#include <stddef.h>
#include <string.h>
#include <assert.h>
#define __thiscall
#include "item_name.h"
static unsigned char actor[0x120];
static const char *text="Blistering Faeblades";
static struct ip_afstring name={&text,0,0,0};
static int calls;
static const struct ip_afstring *read_name(void *p,int decorated) {
    assert(p==actor && decorated==0);++calls;return &name;
}
int main(void) {
    assert(!ip_inventory_name(NULL,read_name));
    assert(!ip_inventory_name(actor,read_name) && calls==0);
    actor[0x10c]=1;
    assert(ip_inventory_name(actor,read_name)==text && calls==1);
    text="Player's custom name";assert(ip_inventory_name(actor,read_name)==text);
    text="";assert(!ip_inventory_name(actor,read_name));
    text=NULL;assert(!ip_inventory_name(actor,read_name));
    name.slot=NULL;assert(!ip_inventory_name(actor,read_name));
    assert(actor[0x10c]==1);return 0;
}
