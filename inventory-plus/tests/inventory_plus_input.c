#include <assert.h>
#include "input.h"
int main(void) {
 struct ip_shortcut_state s={0};
 assert(!ip_search_pressed(&s,1,0,1,0,0));
 assert(ip_search_pressed(&s,1,1,1,0,0));
 assert(!ip_search_pressed(&s,1,1,1,0,0));
 assert(!ip_search_pressed(&s,1,1,0,0,0));
 assert(ip_search_pressed(&s,1,1,1,0,0));
 assert(!ip_search_pressed(&s,0,1,1,0,0));
 assert(!s.held);
 assert(!ip_search_pressed(&s,1,1,1,1,0));
 assert(!ip_search_pressed(&s,1,1,1,0,1));
 assert(ip_search_pressed(&s,1,1,1,0,0));
 assert(!ip_key_matters(0xB3)); /* media Play/Pause: held all session for one tester */
 assert(!ip_key_matters(0xA6) && !ip_key_matters(0xB7) && !ip_key_matters(0xAF));
 assert(ip_key_matters(0xA5) && ip_key_matters(0xB8)); /* right Alt and ';' still count */
 assert(ip_key_matters(1) && ip_key_matters('A') && ip_key_matters(0x11) && ip_key_matters(0x1B));
 return 0;
}
