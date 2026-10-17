#ifndef QUEST_HIDER_VM_BRIDGE_H
#define QUEST_HIDER_VM_BRIDGE_H
/* Named-library registration leaves its table on the Lua value stack. */
typedef int (*qh_lua_function)(void *state);
struct lua_reg { const char *name; qh_lua_function function; };
typedef int (*qh_gettop_fn)(void *state);
typedef void (*qh_register_fn)(void *state,const char *name,const struct lua_reg *functions);
typedef void (*qh_pop_fn)(void *state,int count);
static int qh_register_balanced(void *state,const char *name,const struct lua_reg *functions,
                               qh_gettop_fn gettop,qh_register_fn register_library,qh_pop_fn pop) {
    int before,after,added;
    if(!state||!gettop||!register_library||!pop)return 0;
    before=gettop(state);if(before<0)return 0;
    register_library(state,name,functions);
    after=gettop(state);added=after-before;
    if(added<0||added>16)return 0;
    if(added)pop(state,added);
    return gettop(state)==before;
}
#endif
