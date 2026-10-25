#include <assert.h>
#include <string.h>
#include "store.h"
int main(void) {
 struct qh_store a={{0},0},b={{0},0}; char text[32768]; uint32_t key; unsigned i;
 assert(!qh_key_parse("0",&key)); assert(!qh_key_parse("268435456",&key));
 assert(!qh_key_parse("12x",&key)); assert(qh_key_parse("268435455",&key));
 assert(qh_store_set(&a,42,1)); assert(qh_store_set(&a,42,1)); assert(a.count==1);
 assert(qh_store_set(&a,268435455,1));
 assert(qh_store_encode(&a,"Hero",text,sizeof(text)));
 assert(qh_store_decode(&b,"Hero",text)); assert(b.count==2 && qh_store_has(&b,42));
 assert(!qh_store_decode(&b,"Other",text)); assert(b.count==2);
 assert(!qh_store_decode(&b,"Hero","QuestHider-v1\n4865726f\n42\n42\n")); assert(b.count==2);
 assert(!qh_store_decode(&b,"Hero","QuestHider-v1\n4865726f\n42"));
 assert(!qh_store_decode(&b,"Hero","QuestHider-v1\n4865726f\n268435456\n"));
 assert(qh_store_set(&a,42,0)); assert(!qh_store_has(&a,42));
 a.count=0; for(i=1;i<=QH_MAX_HIDDEN;i++)assert(qh_store_set(&a,i,1));
 assert(!qh_store_set(&a,QH_MAX_HIDDEN+1,1)); assert(a.count==QH_MAX_HIDDEN);
 assert(qh_group_hidden(1,0,0)); assert(!qh_group_hidden(1,1,0));
 assert(!qh_group_hidden(1,0,1)); assert(!qh_group_hidden(0,0,0));
 assert(qh_profile_hash("Hero")!=qh_profile_hash("Other"));
 return 0;
}
