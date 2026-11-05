/* Inventory Plus: input, Unicode lowercase and read-only native inventory names. */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "../../../common/src/vm_bridge.h"
#include "input.h"
#include "item_name.h"
#include "stat_spec.h"
_Static_assert(sizeof(struct ip_afstring)==12,"Engine afstring layout");
#define VA(address) (base+(uintptr_t)(address)-0x00400000u)
static uintptr_t base;
static int supported;
static int stats_ok; /* optional damage/armor readers; never gates the core mod */
static int (__cdecl *gettop)(void*);
static const char *(__cdecl *getstring)(void*,int);
static void (__cdecl *register_library)(void*,const char*,const struct lua_reg*);
static void (__cdecl *pop_values)(void*,int);
static void (__cdecl *pushstring)(void*,const char*);
static uint32_t *(__cdecl *read_actor_handle)(uint32_t *,void *,int);
static void *(__thiscall *lookup_actor)(void *,uint32_t);
static const struct ip_afstring *(__thiscall *actor_name)(void *,int);
static int (__thiscall *read_damage)(void *,uint32_t,int,int);
static int (__thiscall *read_armor)(void *,uint32_t,int,int);
static void *(__stdcall *previous_new_state)(void*);
static struct ip_shortcut_state shortcuts[256];
static int focused(void) {
    DWORD process=0;
    GetWindowThreadProcessId(GetForegroundWindow(),&process);
    return process==GetCurrentProcessId();
}
static int down(int code) {return (GetAsyncKeyState(code)&0x8000)!=0;}
static const char *argument(void *state) {return gettop(state)==1?getstring(state,1):NULL;}
static int api_self_test(void *state) {
    const char *s=argument(state);return s&&!strcmp(s,"InventoryPlus 0.6.0")?1:0;
}
static int api_poll(void *state) {
    const char *s=argument(state);int key;
    if(!s||strlen(s)!=6||strncmp(s,"Ctrl+",5)||(s[5]!='F'&&s[5]!='S'&&s[5]!='D'&&(s[5]<'1'||s[5]>'7')))return 0;
    key=(unsigned char)s[5];
    return ip_search_pressed(&shortcuts[key],focused(),down(VK_CONTROL),down(key),
                             down(VK_MENU)||down(VK_LWIN)||down(VK_RWIN),down(VK_SHIFT));
}
/* Real-time chord state without consuming the shortcut edge: lets the Lua adapter swallow the
 * game's own digit hotkeys (1/2 equip) while Ctrl+digit is held, whichever event arrives first. */
static int api_held(void *state) {
    const char *s=argument(state);
    if(!s||strlen(s)!=6||strncmp(s,"Ctrl+",5)||s[5]<'1'||s[5]>'7'||!focused())return 0;
    return down(VK_CONTROL)&&down((unsigned char)s[5])?1:0;
}
static int api_idle(void *state) {
    int code;
    if(!argument(state)||!focused())return 0;
    for(code=1;code<256;++code)if(down(code))return 0;
    return 1;
}
/* Invariant Unicode lowercase, preserving accents. Returned text is UTF-8. */
static int api_fold(void *state) {
    const char *s=argument(state);wchar_t *wide=NULL,*lower=NULL;char *out=NULL;
    int n,m,bytes,result=0;HANDLE heap=GetProcessHeap();
    if(!s||strlen(s)>16384)return 0;
    if(!*s) {pushstring(state,"");return 1;}
    n=MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,s,-1,NULL,0);if(!n)return 0;
    wide=HeapAlloc(heap,0,(size_t)n*sizeof(*wide));if(!wide)goto done;
    if(!MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,s,-1,wide,n))goto done;
    m=LCMapStringEx(LOCALE_NAME_INVARIANT,LCMAP_LOWERCASE,wide,-1,NULL,0,NULL,NULL,0);if(!m)goto done;
    lower=HeapAlloc(heap,0,(size_t)m*sizeof(*lower));if(!lower)goto done;
    if(!LCMapStringEx(LOCALE_NAME_INVARIANT,LCMAP_LOWERCASE,wide,-1,lower,m,NULL,NULL,0))goto done;
    bytes=WideCharToMultiByte(CP_UTF8,WC_ERR_INVALID_CHARS,lower,-1,NULL,0,NULL,NULL);if(!bytes)goto done;
    out=HeapAlloc(heap,0,(size_t)bytes);if(!out)goto done;
    if(!WideCharToMultiByte(CP_UTF8,WC_ERR_INVALID_CHARS,lower,-1,out,bytes,NULL,NULL))goto done;
    pushstring(state,out);result=1;
 done:
    if(out)HeapFree(heap,0,out);if(lower)HeapFree(heap,0,lower);if(wide)HeapFree(heap,0,wide);
    return result;
}
/* Same handle decoder and actor::name(false) used by the native label formatter. */
static int api_item_name(void *state) {
    uint32_t handle=0;void *manager,*actor;const char *text;
    if(gettop(state)!=1)return 0;
    read_actor_handle(&handle,state,1);if(!handle)return 0;
    manager=*(void **)VA(0x19fec38);if(!manager)return 0;
    actor=lookup_actor((char *)manager+0x2238,handle);
    text=ip_inventory_name(actor,actor_name);if(!text)return 0;
    pushstring(state,text);return 1;
}
/* Read-only per-actor damage/armor tables (14 slots). Returns false for stale handles. */
static int stat_context(void *state,uint32_t *handle,void **stats,void **actor) {
    void *manager;
    *handle=0;read_actor_handle(handle,state,1);if(!*handle)return 0;
    manager=*(void **)VA(0x19fec38);if(!manager)return 0;
    *actor=lookup_actor((char *)manager+0x2238,*handle);
    if(!*actor||!(*(const uint8_t *)((const char *)*actor+0x10c)&1))return 0;
    *stats=*(void **)VA(0x19fe9c4);if(!*stats)return 0;
    *stats=(char *)*stats+0x3d28;return 1;
}
/* stat(handle, "d"|"a" .. two-digit slot .. "0"|"1" scaled) -> integer text, e.g. "d001". */
static int api_stat(void *state) {
    uint32_t handle;void *stats,*actor;char out[16];int armor,index,scaled,value;
    if(!stats_ok||gettop(state)!=2||!ip_parse_stat_spec(getstring(state,2),&armor,&index,&scaled))return 0;
    if(!stat_context(state,&handle,&stats,&actor))return 0;
    value=armor?read_armor(stats,handle,index,scaled):read_damage(stats,handle,index,scaled);
    snprintf(out,sizeof(out),"%d",value);pushstring(state,out);return 1;
}
/* stats(handle) -> name, damage raw, damage scaled, armor raw, armor scaled (14 ints each). */
static int api_stats(void *state) {
    uint32_t handle;void *stats,*actor;const char *name;char row[256];int kind,scaled,index,used;
    if(!stats_ok||gettop(state)!=1||!stat_context(state,&handle,&stats,&actor))return 0;
    name=ip_inventory_name(actor,actor_name);if(!name)return 0;
    pushstring(state,name);
    for(kind=0;kind<2;++kind)for(scaled=0;scaled<2;++scaled) {
        used=0;row[0]=0;
        for(index=0;index<14;++index) {
            int value=kind?read_armor(stats,handle,index,scaled):read_damage(stats,handle,index,scaled);
            used+=snprintf(row+used,sizeof(row)-(size_t)used,index?",%d":"%d",value);
        }
        pushstring(state,row);
    }
    return 5;
}
/* A Lua C function's return value counts pushed results, so push the answer as text. */
static int api_has_stats(void *state) {pushstring(state,stats_ok?"1":"0");return 1;}
static const struct lua_reg functions[]={
    {"self_test",api_self_test},{"poll",api_poll},{"held",api_held},{"idle",api_idle},{"fold",api_fold},{"item_name",api_item_name},{"stat",api_stat},{"stats",api_stats},{"has_stats",api_has_stats},{NULL,NULL}
};
static void register_state(void *state) {
    if(!qh_register_balanced(state,"InventoryPlusNative",functions,gettop,register_library,pop_values))supported=0;
}
static void *__stdcall new_state(void *state) {
    void *result=previous_new_state(state);
    if(result&&supported)register_state(result);
    return result;
}
static int resolve_api(void) {
    IMAGE_DOS_HEADER *dos;IMAGE_NT_HEADERS32 *pe;
    static const unsigned char top[]={0x8b,0x4c,0x24,0x04,0x8b,0x41,0x24,0x2b,0x41,0x28,0xc1,0xf8,0x03,0xc3};
    static const unsigned char pop[]={0x8b,0x4c,0x24,0x08,0x8b,0x44,0x24,0x04,0xf7,0xd9,0x03,0xc9,0x03,0xc9,0x03,0xc9,0x01,0x48,0x24,0xc3};
    static const unsigned char string[]={0x8b,0x4c,0x24,0x08,0x81,0xf9,0xf0,0xd8,0xff,0xff,0x7e,0x35};
    static const unsigned char reg[]={0x8b,0x44,0x24,0x0c,0x8b,0x4c,0x24,0x08,0x56,0x8b,0x74,0x24,0x08,0x6a,0x00,0x6a,0x00,0x50,0x51,0xe8};
    static const unsigned char push[]={0x8b,0x54,0x24,0x08,0x85,0xd2,0x75,0x10,0x8b,0x4c,0x24,0x04};
    static const unsigned char decode[]={0x53,0x56,0x8b,0x74,0x24,0x10,0x57,0x8b,0x7c,0x24,0x18,0x57};
    static const unsigned char lookup[]={0x8b,0x54,0x24,0x04,0x56,0xf7,0xc2,0x00,0x00,0xff,0x0f,0x74};
    static const unsigned char damage[]={0x83,0xec,0x08,0x8b,0x44,0x24,0x0c,0x57,0x6a,0x0b,0xbf}; /* then a relocated imm32 */
    static const unsigned char armor[]={0x83,0xec,0x08,0x8b,0x44,0x24,0x0c,0x57,0x6a,0x0c,0xbf}; /* then a relocated imm32 */
    static const unsigned char name[]={0x80,0xb9,0x1c,0x01,0x00,0x00,0x00,0x74,0x0d,0x80,0x7c,0x24};
    base=(uintptr_t)GetModuleHandleA(NULL);dos=(IMAGE_DOS_HEADER*)base;
    if(dos->e_magic!=IMAGE_DOS_SIGNATURE)return 0;
    pe=(IMAGE_NT_HEADERS32*)(base+dos->e_lfanew);
    if(pe->Signature!=IMAGE_NT_SIGNATURE||pe->FileHeader.Machine!=IMAGE_FILE_MACHINE_I386||pe->FileHeader.TimeDateStamp!=0x63f74827||pe->OptionalHeader.SizeOfImage!=0x0173d000)return 0;
    if(memcmp((void*)VA(0xa9f980),top,sizeof(top))||memcmp((void*)VA(0xa9f9a0),pop,sizeof(pop))||memcmp((void*)VA(0xa9f8b0),string,sizeof(string))||memcmp((void*)VA(0x10adca0),reg,sizeof(reg))||memcmp((void*)VA(0xaa3560),push,sizeof(push)))return 0;
    if(memcmp((void*)VA(0xe5f770),decode,sizeof(decode))||memcmp((void*)VA(0xf23c10),lookup,sizeof(lookup))||memcmp((void*)VA(0xef3b20),name,sizeof(name)))return 0;
    /* Optional stat readers: a mismatch disables only damage/armor sorting. The imm32 is an
       absolute address the loader rebases, so compare it to the actual base. */
    stats_ok=!memcmp((void*)VA(0xe42140),damage,sizeof(damage))&&!memcmp((void*)VA(0xe421d0),armor,sizeof(armor))
        &&*(uint32_t*)(VA(0xe42140)+sizeof(damage))==(uint32_t)VA(0x1741aac)
        &&*(uint32_t*)(VA(0xe421d0)+sizeof(armor))==(uint32_t)VA(0x1741aac);
    if(stats_ok){read_damage=(void*)VA(0xe42140);read_armor=(void*)VA(0xe421d0);}
    read_actor_handle=(void*)VA(0xe5f770);lookup_actor=(void*)VA(0xf23c10);actor_name=(void*)VA(0xef3b20);
    gettop=(void*)VA(0xa9f980);pop_values=(void*)VA(0xa9f9a0);getstring=(void*)VA(0xa9f8b0);register_library=(void*)VA(0x10adca0);pushstring=(void*)VA(0xaa3560);
    return 1;
}
static int hook_framework(void) {
    static const unsigned char prefix[]={0x8b,0x47,0x08,0xff,0x88,0xdc,0x02,0x00,0x00,0x8b,0xc7,0x5f,0x5e,0x5d,0x5b,0x59};
    unsigned char *start=(void*)VA(0x10d2c25),*call=start+17;DWORD protection,ignored;int32_t old,delta;
    if(memcmp(start,prefix,sizeof(prefix))||start[16]!=0x50||call[0]!=0xe8||call[5]!=0xc3)return 0;
    memcpy(&old,call+1,4);previous_new_state=(void*)(call+5+old);
    if((uintptr_t)previous_new_state>=base&&(uintptr_t)previous_new_state<base+0x173d000)return 0;
    delta=(int32_t)((uintptr_t)&new_state-(uintptr_t)(call+5));
    if(!VirtualProtect(call+1,4,PAGE_EXECUTE_READWRITE,&protection))return 0;
    memcpy(call+1,&delta,4);FlushInstructionCache(GetCurrentProcess(),call+1,4);
    VirtualProtect(call+1,4,protection,&ignored);return 1;
}
BOOL WINAPI DllMain(HINSTANCE module,DWORD reason,LPVOID reserved) {
    (void)reserved;
    if(reason==DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(module);
        supported=resolve_api();if(supported)supported=hook_framework();
    }
    return TRUE;
}
