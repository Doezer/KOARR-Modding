#include <assert.h>
#include <stdio.h>
#include "stat_spec.h"
int main(void) {
    int armor=9,index=9,scaled=9;
    assert(ip_parse_stat_spec("d001",&armor,&index,&scaled)&&!armor&&index==0&&scaled==1);
    assert(ip_parse_stat_spec("a130",&armor,&index,&scaled)&&armor&&index==13&&scaled==0);
    assert(ip_parse_stat_spec("d090",&armor,&index,&scaled)&&index==9);
    assert(!ip_parse_stat_spec("d140",&armor,&index,&scaled)); /* slot 14 does not exist */
    assert(!ip_parse_stat_spec("d002",&armor,&index,&scaled)); /* scaled is 0 or 1 */
    assert(!ip_parse_stat_spec("x000",&armor,&index,&scaled));
    assert(!ip_parse_stat_spec("d01",&armor,&index,&scaled));
    assert(!ip_parse_stat_spec("d0011",&armor,&index,&scaled));
    assert(!ip_parse_stat_spec("d0a1",&armor,&index,&scaled));
    assert(!ip_parse_stat_spec(NULL,&armor,&index,&scaled));
    puts("Stat spec parser passed");
    return 0;
}
