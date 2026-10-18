#ifndef INVENTORY_PLUS_ITEM_NAME_H
#define INVENTORY_PLUS_ITEM_NAME_H
#include <stdint.h>
#include <stddef.h>
/* The native label formatter (0x00ECDC20) calls actor::name(false), not
 * ACTOR.get_actor_display_name. afstring's first pointer owns a char* slot.
 * Borrow the text only until lua_pushstring copies it; never release/mutate it. */
struct ip_afstring { const char **slot; uint32_t hash; uint16_t length; uint8_t flags; };
static const char *ip_inventory_name(void *actor,
    const struct ip_afstring *(__thiscall *name)(void *,int)) {
    const struct ip_afstring *value;
    if(!actor || !(*(const uint8_t *)((const char *)actor+0x10c)&1))return NULL;
    value=name(actor,0);
    return value && value->slot && *value->slot && **value->slot ? *value->slot : NULL;
}
#endif
