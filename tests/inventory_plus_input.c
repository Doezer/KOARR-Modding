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
 return 0;
}
