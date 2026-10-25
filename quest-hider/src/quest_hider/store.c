#include "store.h"
#include <string.h>
#include <stdio.h>
int qh_key_parse(const char *s, uint32_t *key) {
    uint32_t value = 0; size_t n = 0;
    if (!s || !*s) return 0;
    while (*s) {
        unsigned digit = (unsigned)(*s++ - '0');
        if (digit > 9 || ++n > 9 || value > (0x0fffffffu - digit) / 10u) return 0;
        value = value * 10u + digit;
    }
    if (!value) return 0;
    *key = value; return 1;
}
int qh_store_has(const struct qh_store *s, uint32_t key) {
    size_t i; for (i = 0; i < s->count; ++i) if (s->keys[i] == key) return 1;
    return 0;
}
int qh_store_set(struct qh_store *s, uint32_t key, int hidden) {
    size_t i;
    if (!key || key > 0x0fffffffu) return 0;
    for (i = 0; i < s->count; ++i) if (s->keys[i] == key) {
        if (!hidden) { memmove(s->keys+i,s->keys+i+1,(s->count-i-1)*sizeof(uint32_t)); --s->count; }
        return 1;
    }
    if (!hidden) return 1;
    if (s->count == QH_MAX_HIDDEN) return 0;
    s->keys[s->count++] = key; return 1;
}
uint64_t qh_profile_hash(const char *s) {
    uint64_t h = UINT64_C(14695981039346656037);
    while (*s) { h ^= (unsigned char)*s++; h *= UINT64_C(1099511628211); }
    return h;
}
static int header(const char *profile, char *out, size_t cap) {
    static const char hex[] = "0123456789abcdef";
    size_t n = strlen(profile), i, at = 0;
    const char *magic = "QuestHider-v1\n";
    if (!n || n > QH_MAX_PROFILE || cap < strlen(magic)+2*n+2) return 0;
    memcpy(out, magic, strlen(magic)); at = strlen(magic);
    for (i=0;i<n;++i) { unsigned b=(unsigned char)profile[i];out[at++]=hex[b>>4];out[at++]=hex[b&15]; }
    out[at++]='\n';out[at]=0;return (int)at;
}
int qh_store_encode(const struct qh_store *s,const char *profile,char *out,size_t cap) {
    int length=header(profile,out,cap);size_t i,at;
    if (!length || s->count>QH_MAX_HIDDEN) return 0;
    at=(size_t)length;
    for(i=0;i<s->count;++i) {
        int n=snprintf(out+at,cap-at,"%u\n",(unsigned)s->keys[i]);
        if(n<0 || (size_t)n>=cap-at)return 0;
        at+=(size_t)n;
    }
    return (int)at;
}
int qh_store_decode(struct qh_store *s,const char *profile,const char *text) {
    char expected[QH_MAX_PROFILE*2+32],line[16];struct qh_store candidate={{0},0};
    int n=header(profile,expected,sizeof(expected));size_t len;
    if (!n || strncmp(text,expected,(size_t)n)) return 0;
    text+=n;
    while(*text) {
        const char *end=strchr(text,'\n');uint32_t key;
        if(!end || (len=(size_t)(end-text))==0 || len>=sizeof(line))return 0;
        memcpy(line,text,len);line[len]=0;
        if(!qh_key_parse(line,&key) || qh_store_has(&candidate,key) || !qh_store_set(&candidate,key,1))return 0;
        text=end+1;
    }
    *s=candidate;return 1;
}
int qh_group_hidden(unsigned hidden,unsigned visible,unsigned unknown) {
    return hidden>0 && visible==0 && unknown==0;
}
