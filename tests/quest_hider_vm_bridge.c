#include <assert.h>
#include <string.h>
#include "vm_bridge.h"
struct state { int top,slots[512],mode,pops,registered; };
static int top(void *p) { return ((struct state*)p)->top; }
static void pop(void *p,int n) {
    struct state *s=p;assert(n>0&&n<=s->top);s->top-=n;s->pops++;
}
static void reg(void *p,const char *name,const struct lua_reg *functions) {
    struct state *s=p;assert(!strcmp(name,"QuestHiderNative"));assert(functions);
    s->registered++;
    if(s->mode==1){s->top--;return;}
    if(s->mode==2){s->top+=17;return;}
    s->slots[s->top++]=999;
}
int main(void) {
    const struct lua_reg functions[]={{0,0}};
    struct state s={0};int i;
    s.top=3;s.slots[0]=11;s.slots[1]=22;s.slots[2]=33;
    for(i=0;i<200;i++)assert(qh_register_balanced(&s,"QuestHiderNative",functions,top,reg,pop));
    assert(s.top==3&&s.pops==200&&s.registered==200);
    assert(s.slots[0]==11&&s.slots[1]==22&&s.slots[2]==33);
    s.mode=1;assert(!qh_register_balanced(&s,"QuestHiderNative",functions,top,reg,pop));assert(s.pops==200);
    s.mode=2;assert(!qh_register_balanced(&s,"QuestHiderNative",functions,top,reg,pop));assert(s.pops==200);
    assert(!qh_register_balanced(0,"QuestHiderNative",functions,top,reg,pop));
    return 0;
}
