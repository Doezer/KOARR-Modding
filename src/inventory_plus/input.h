#ifndef INVENTORY_PLUS_INPUT_H
#define INVENTORY_PLUS_INPUT_H
struct ip_shortcut_state { int held; };
static int ip_search_pressed(struct ip_shortcut_state *state,int focused,int ctrl,int key,int alt,int shift) {
    int pressed=ctrl&&key&&!alt&&!shift;
    int fire;
    if(!focused) {state->held=0;return 0;}
    fire=pressed&&!state->held;
    state->held=pressed;
    return fire;
}
#endif
