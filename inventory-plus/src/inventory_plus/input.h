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
/* Browser, volume, media and launch keys (0xA6..0xB7) and IME placeholders can read as held for a
 * whole session (a headset or media controller held Play/Pause, VK 0xB3, for one tester). They are
 * not game input, so idle() must not wait for them. */
static int ip_key_matters(int code) {
    return !((code>=0xA6&&code<=0xB7)||code==0xE5||code==0xE7);
}
#endif
