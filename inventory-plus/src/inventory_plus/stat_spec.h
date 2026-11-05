#ifndef INVENTORY_PLUS_STAT_SPEC_H
#define INVENTORY_PLUS_STAT_SPEC_H
#include <string.h>
/* "d" or "a", a two-digit slot 00..13, then scaled flag 0 or 1: e.g. "d001". */
static int ip_parse_stat_spec(const char *spec,int *armor,int *index,int *scaled) {
    int value;
    if(!spec||strlen(spec)!=4)return 0;
    if(spec[0]!='d'&&spec[0]!='a')return 0;
    if(spec[1]<'0'||spec[1]>'1'||spec[2]<'0'||spec[2]>'9'||(spec[3]!='0'&&spec[3]!='1'))return 0;
    value=(spec[1]-'0')*10+(spec[2]-'0');
    if(value>13)return 0;
    *armor=spec[0]=='a';*index=value;*scaled=spec[3]-'0';return 1;
}
#endif
