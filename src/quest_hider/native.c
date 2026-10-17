/* Quest Hider preview: exact-build, read-only game inspection and display filtering. */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <bcrypt.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include "store.h"
#include "vm_bridge.h"
#define VA(address) (base + (uintptr_t)(address) - 0x00400000u)
#define QH_CACHE_MAX 4096
#define QH_FILE_MAX 32768
static uintptr_t base;
static HMODULE own_module;
static int supported, initialized, profile_active;
static char profile_name[QH_MAX_PROFILE+1], profile_file[MAX_PATH];
static struct qh_store hidden_store;
static uintptr_t profile_player;
static uint32_t hidden_objects[QH_CACHE_MAX];
static size_t hidden_object_count;
static DWORD last_cache;
static int cache_dirty=1;
static unsigned char key_down[256];
void *qh_render_continue, *qh_render_skip;
void qh_render_hook(void);
static int (__cdecl *lua_gettop)(void*);
static void (__cdecl *lua_pop_values)(void*,int);
static const char *(__cdecl *lua_tostring)(void*,int);
static void (__cdecl *lua_register)(void*,const char*,const struct lua_reg*);
static void *(__stdcall *previous_new_state)(void*);
static void log_line(const char *format,...) {
    char text[1024];DWORD written;va_list args;int n;
    memcpy(text,"[QuestHider][native] ",21);
    va_start(args,format);n=vsnprintf(text+21,sizeof(text)-23,format,args);va_end(args);
    if(n<0)return;
    text[sizeof(text)-3]=0;n=(int)strlen(text);text[n++]='\n';
    WriteFile(GetStdHandle(STD_OUTPUT_HANDLE),text,(DWORD)n,&written,NULL);
    /* One synchronous output path: do not also call a debugger/overlay sink. */
    text[n]=0;
}
static int read_memory(uintptr_t address,void *out,size_t size) {
    SIZE_T got=0;
    return address && ReadProcessMemory(GetCurrentProcess(),(void*)address,out,size,&got) && got==size;
}
static uintptr_t pointer_at(uintptr_t address) { uintptr_t p=0;read_memory(address,&p,sizeof(p));return p; }
static int integer_at(uintptr_t address,int *out) { return read_memory(address,out,sizeof(*out)); }
static int patch_memory(void *address,const void *bytes,size_t count) {
    DWORD previous,ignored;
    if(!VirtualProtect(address,count,PAGE_EXECUTE_READWRITE,&previous))return 0;
    memcpy(address,bytes,count);FlushInstructionCache(GetCurrentProcess(),address,count);
    if(!VirtualProtect(address,count,previous,&ignored))log_line("Could not restore code page protection");
    return 1;
}
static uintptr_t player_token(void) {
    uintptr_t root=pointer_at(VA(0x019fd5e4));
    typedef void *(__thiscall *get_player_fn)(void*,int);
    if(!root)return 0;
    return (uintptr_t)((get_player_fn)VA(0x00b6e220))((void*)(root+0x164c),0);
}
static int exact_executable(void) {
    static const char expected_hex[]="16a400f6e8fc10dbe446a9e57717de9fbe975ef17c004f4ca405e2e4e09cb314";
    BCRYPT_ALG_HANDLE algorithm=NULL;BCRYPT_HASH_HANDLE hash=NULL;
    HANDLE file=INVALID_HANDLE_VALUE;unsigned char buffer[65536],digest[32];
    char path[MAX_PATH],hex[65];DWORD size=0,i;int ok=0;
    if(!GetModuleFileNameA(NULL,path,sizeof(path)))goto done;
    file=CreateFileA(path,GENERIC_READ,FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE,NULL,OPEN_EXISTING,0,NULL);
    if(file==INVALID_HANDLE_VALUE)goto done;
    if(BCryptOpenAlgorithmProvider(&algorithm,BCRYPT_SHA256_ALGORITHM,NULL,0)<0)goto done;
    if(BCryptCreateHash(algorithm,&hash,NULL,0,NULL,0,0)<0)goto done;
    for(;;) {
        if(!ReadFile(file,buffer,sizeof(buffer),&size,NULL))goto done;
        if(!size)break;
        if(BCryptHashData(hash,buffer,size,0)<0)goto done;
    }
    if(BCryptFinishHash(hash,digest,sizeof(digest),0)<0)goto done;
    for(i=0;i<32;++i)snprintf(hex+2*i,3,"%02x",digest[i]);
    ok=!strcmp(hex,expected_hex);
 done:
    if(hash)BCryptDestroyHash(hash);if(algorithm)BCryptCloseAlgorithmProvider(algorithm,0);
    if(file!=INVALID_HANDLE_VALUE)CloseHandle(file);return ok;
}
static int save_store(const struct qh_store *store) {
    char text[QH_FILE_MAX],temporary[MAX_PATH];int length;DWORD written;HANDLE file;
    length=qh_store_encode(store,profile_name,text,sizeof(text));if(!length)return 0;
    if(snprintf(temporary,sizeof(temporary),"%s.tmp",profile_file)>=(int)sizeof(temporary))return 0;
    file=CreateFileA(temporary,GENERIC_WRITE,0,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL);
    if(file==INVALID_HANDLE_VALUE)return 0;
    if(!WriteFile(file,text,(DWORD)length,&written,NULL)||written!=(DWORD)length||!FlushFileBuffers(file)) {
        CloseHandle(file);DeleteFileA(temporary);return 0;
    }
    CloseHandle(file);
    if(!MoveFileExA(temporary,profile_file,MOVEFILE_REPLACE_EXISTING|MOVEFILE_WRITE_THROUGH)) {
        DeleteFileA(temporary);return 0;
    }
    return 1;
}
static int open_profile(const char *name) {
    char path[MAX_PATH],folder[MAX_PATH],text[QH_FILE_MAX];DWORD got=0,size;HANDLE file;
    struct qh_store candidate={{0},0};uintptr_t player=player_token();uint64_t hash;
    if(!name||!*name||strlen(name)>QH_MAX_PROFILE||!player)return 0;
    if(profile_active && profile_player==player && !strcmp(profile_name,name))return 1;
    profile_active=0;hidden_object_count=0;cache_dirty=1;
    if(!GetModuleFileNameA(own_module,path,sizeof(path)))return 0;
    { char *slash=strrchr(path,'\\');if(!slash)return 0;*slash=0; }
    if(snprintf(folder,sizeof(folder),"%s\\QuestHider",path)>=(int)sizeof(folder))return 0;
    CreateDirectoryA(folder,NULL);
    if(snprintf(folder,sizeof(folder),"%s\\QuestHider\\profiles",path)>=(int)sizeof(folder))return 0;
    if(!CreateDirectoryA(folder,NULL)&&GetLastError()!=ERROR_ALREADY_EXISTS)return 0;
    hash=qh_profile_hash(name);
    if(snprintf(profile_file,sizeof(profile_file),"%s\\%016llx.txt",folder,(unsigned long long)hash)>=(int)sizeof(profile_file))return 0;
    file=CreateFileA(profile_file,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL);
    if(file!=INVALID_HANDLE_VALUE) {
        size=GetFileSize(file,NULL);
        if(size>=sizeof(text)||!ReadFile(file,text,size,&got,NULL)||got!=size) {CloseHandle(file);return 0;}
        CloseHandle(file);if(memchr(text,0,got))return 0;text[got]=0;
        if(!qh_store_decode(&candidate,name,text)) {log_line("Invalid preference file; filtering remains disabled");return 0;}
    } else if(GetLastError()!=ERROR_FILE_NOT_FOUND)return 0;
    hidden_store=candidate;strcpy(profile_name,name);profile_player=player;profile_active=1;
    log_line("Profile loaded (%u hidden quests)",(unsigned)hidden_store.count);return 1;
}
static void rebuild_marker_cache(void) {
    uintptr_t owners[QH_MAX_HIDDEN],game,manager,flags,objects,groups;size_t owner_count=0,i;
    int group_count,g;typedef int (__thiscall *lookup_fn)(void*,uint32_t);
    hidden_object_count=0;cache_dirty=0;last_cache=GetTickCount();
    manager=pointer_at(VA(0x019f4e14));game=pointer_at(VA(0x019fe9c4));
    if(!manager||!game)return;
    flags=pointer_at(manager+0x28);objects=pointer_at(manager+0x18);if(!flags||!objects)return;
    for(i=0;i<hidden_store.count;++i) {
        int handle=((lookup_fn)VA(0x00a70b80))((void*)manager,hidden_store.keys[i]);unsigned char status=0;uintptr_t owner;
        if(handle<2 || handle>32767 || !read_memory(flags+(unsigned)handle,&status,1)||!(status&4))continue;
        owner=pointer_at(objects+4*(unsigned)handle);if(owner)owners[owner_count++]=owner;
    }
    if(!owner_count)return;
    groups=pointer_at(game+0x8224);
    if(!integer_at(game+0x8228,&group_count)||group_count<0||group_count>10000||!groups)return;
    for(g=0;g<group_count && hidden_object_count<QH_CACHE_MAX;++g) {
        uintptr_t targets=pointer_at(groups+16u*(unsigned)g);int count,j,object_id=-1;unsigned hide=0,show=0,unknown=0;
        if(!integer_at(groups+16u*(unsigned)g+4,&count)||count<0||count>10000)continue;
        for(j=0;j<count;++j) {
            uintptr_t target=pointer_at(targets+4u*(unsigned)j),owner;int kind,id;size_t k;
            if(!target||!integer_at(target+0x2c,&kind)) {unknown=1;break;}
            if(kind!=0)continue;
            if(!integer_at(target+0x28,&id)||id<2) {unknown=1;break;}
            if(object_id!=-1 && object_id!=id) {unknown=1;break;}object_id=id;
            owner=pointer_at(target+0x30);if(!owner) {unknown=1;break;}
            for(k=0;k<owner_count && owners[k]!=owner;++k){}
            if(k<owner_count)++hide;else ++show;
        }
        if(object_id>=2 && qh_group_hidden(hide,show,unknown))hidden_objects[hidden_object_count++]=(uint32_t)object_id;
    }
}
int __cdecl qh_should_hide_marker(const void *group,const void *entry) {
    uintptr_t icon,object;int icon_type,id;size_t i;
    if(!profile_active||!hidden_store.count)return 0;
    icon=pointer_at((uintptr_t)entry);
    if(!icon||!integer_at(icon+0xc,&icon_type)||(icon_type!=0x007f3718 && icon_type!=0x01ab7635))return 0;
    if(player_token()!=profile_player) {profile_active=0;hidden_object_count=0;return 0;}
    if(cache_dirty || (DWORD)(GetTickCount()-last_cache)>200)rebuild_marker_cache();
    object=pointer_at((uintptr_t)group);
    if(!object||!integer_at(object+0x10,&id))return 0;
    for(i=0;i<hidden_object_count;++i)if(hidden_objects[i]==(uint32_t)id)return 1;
    return 0;
}
static const char *arg(void *state,int index,int count) {
    if(!lua_gettop||lua_gettop(state)!=count)return NULL;
    return lua_tostring(state,index);
}
static int api_self_test(void *state) {
    const char *s=arg(state,1,1);
    /* Exercise the same C-to-Lua return convention, without patching or game inspection. */
    return s&&!strcmp(s,"QuestHider bridge 0.1.2")?1:0;
}
static int api_initialize(void *state) {
    static const unsigned char expected[]={0xf6,0x45,0x04,0x01,0x0f,0x85,0x0f,0x06,0x00,0x00};
    unsigned char patch[sizeof(expected)];int32_t delta;
    if(!arg(state,1,1)||!supported)return 0;
    if(initialized)return 1;
    if(!exact_executable()) {log_line("Unsupported executable SHA-256; Quest Hider disabled");return 0;}
    if(memcmp((void*)VA(0x01006cfb),expected,sizeof(expected))) {log_line("Renderer code conflict; Quest Hider disabled");return 0;}
    memset(patch,0x90,sizeof(patch));patch[0]=0xe9;
    delta=(int32_t)((uintptr_t)&qh_render_hook-(VA(0x01006cfb)+5));memcpy(patch+1,&delta,4);
    qh_render_continue=(void*)VA(0x01006d05);qh_render_skip=(void*)VA(0x01007314);
    if(!patch_memory((void*)VA(0x01006cfb),patch,sizeof(patch)))return 0;
    initialized=1;log_line("Exact-build renderer filter installed");return 1;
}
static int api_profile(void *state) {const char *s=arg(state,1,1);return initialized&&s&&open_profile(s)?1:0;}
static int api_suspend(void *state) {(void)state;profile_active=0;hidden_object_count=0;return 0;}
static int api_has(void *state) {uint32_t key;const char *s=arg(state,1,1);return profile_active&&s&&qh_key_parse(s,&key)&&qh_store_has(&hidden_store,key)?1:0;}
static int api_set(void *state) {
    const char *key_text=arg(state,1,2),*action=arg(state,2,2);uint32_t key;struct qh_store candidate;
    if(!profile_active||!key_text||!action||!qh_key_parse(key_text,&key))return 0;
    if(strcmp(action,"hide")&&strcmp(action,"show"))return 0;
    candidate=hidden_store;
    if(!qh_store_set(&candidate,key,!strcmp(action,"hide"))||!save_store(&candidate)) {log_line("Preference save failed; previous state retained");return 0;}
    hidden_store=candidate;cache_dirty=1;return 1;
}
static int api_poll(void *state) {
    const char *s=arg(state,1,1);int code=0,pressed;DWORD process=0;
    if(!s||sscanf(s,"%d",&code)!=1||code<1||code>255)return 0;
    GetWindowThreadProcessId(GetForegroundWindow(),&process);
    if(process!=GetCurrentProcessId()) {key_down[code]=0;return 0;}
    pressed=(GetAsyncKeyState(code)&0x8000)!=0;
    if(pressed&&!key_down[code]) {key_down[code]=1;return 1;}
    key_down[code]=(unsigned char)pressed;return 0;
}
static const struct lua_reg functions[]={
    {"self_test",api_self_test},{"initialize",api_initialize},{"profile",api_profile},{"suspend",api_suspend},
    {"is_hidden",api_has},{"set_hidden",api_set},{"poll",api_poll},{NULL,NULL}
};
static int resolve_api(void) {
    IMAGE_DOS_HEADER *dos;IMAGE_NT_HEADERS32 *pe;
    static const unsigned char top[]={0x8b,0x4c,0x24,0x04,0x8b,0x41,0x24,0x2b,0x41,0x28,0xc1,0xf8,0x03,0xc3};
    static const unsigned char pop[]={0x8b,0x4c,0x24,0x08,0x8b,0x44,0x24,0x04,0xf7,0xd9,0x03,0xc9,0x03,0xc9,0x03,0xc9,0x01,0x48,0x24,0xc3};
    static const unsigned char reg[]={0x8b,0x44,0x24,0x0c,0x8b,0x4c,0x24,0x08,0x56,0x8b,0x74,0x24,0x08,0x6a,0x00,0x6a,0x00,0x50,0x51,0xe8};
    static const unsigned char string[]={0x8b,0x4c,0x24,0x08,0x81,0xf9,0xf0,0xd8,0xff,0xff,0x7e,0x35};
    base=(uintptr_t)GetModuleHandleA(NULL);dos=(IMAGE_DOS_HEADER*)base;
    if(dos->e_magic!=IMAGE_DOS_SIGNATURE)return 0;pe=(IMAGE_NT_HEADERS32*)(base+dos->e_lfanew);
    if(pe->Signature!=IMAGE_NT_SIGNATURE||pe->FileHeader.Machine!=IMAGE_FILE_MACHINE_I386||pe->FileHeader.TimeDateStamp!=0x63f74827||pe->OptionalHeader.SizeOfImage!=0x0173d000)return 0;
    if(memcmp((void*)VA(0x00a9f9a0),pop,sizeof(pop))||memcmp((void*)VA(0x00a9f980),top,sizeof(top))||memcmp((void*)VA(0x010adca0),reg,sizeof(reg))||memcmp((void*)VA(0x00a9f8b0),string,sizeof(string)))return 0;
    lua_pop_values=(void*)VA(0x00a9f9a0);lua_gettop=(void*)VA(0x00a9f980);lua_tostring=(void*)VA(0x00a9f8b0);lua_register=(void*)VA(0x010adca0);
    return 1;
}
static void register_library(void *state) {
    if(!qh_register_balanced(state,"QuestHiderNative",functions,lua_gettop,lua_register,lua_pop_values)) {
        supported=0;log_line("Lua registration stack imbalance; helper disabled");
    }
}
static void *__stdcall wrapped_new_state(void *state) {
    void *result=previous_new_state(state);
    if(result&&supported)register_library(result);return result;
}
static void hook_framework_state(void) {
    static const unsigned char prefix[]={0x8b,0x47,0x08,0xff,0x88,0xdc,0x02,0x00,0x00,0x8b,0xc7,0x5f,0x5e,0x5d,0x5b,0x59};
    uintptr_t start=VA(0x010d2c25);unsigned char *call=(unsigned char*)(start+17);int32_t old,new_delta;
    if(memcmp((void*)start,prefix,sizeof(prefix))||*(unsigned char*)(start+16)!=0x50||call[0]!=0xe8||call[5]!=0xc3) {
        log_line("Framework state hook unavailable; Lua adapter will stay disabled without registration");return;
    }
    memcpy(&old,call+1,4);previous_new_state=(void*)(call+5+old);
    if((uintptr_t)previous_new_state>=base && (uintptr_t)previous_new_state<base+0x173d000) {previous_new_state=NULL;return;}
    new_delta=(int32_t)((uintptr_t)&wrapped_new_state-(uintptr_t)(call+5));
    if(patch_memory(call+1,&new_delta,4))log_line("Chained framework Lua registration hook");
}
__declspec(dllexport) int __cdecl luaopen_QuestHiderNative(void *state) {
    if(supported)register_library(state);return 0;
}
BOOL WINAPI DllMain(HINSTANCE instance,DWORD reason,LPVOID reserved) {
    (void)reserved;
    if(reason==DLL_PROCESS_ATTACH) {
        own_module=instance;DisableThreadLibraryCalls(instance);supported=resolve_api();
        if(supported)hook_framework_state();else log_line("Unsupported PE build; native helper inactive");
    }
    return TRUE;
}
