#ifndef QUEST_HIDER_STORE_H
#define QUEST_HIDER_STORE_H
#include <stddef.h>
#include <stdint.h>
#define QH_MAX_HIDDEN 1024
#define QH_MAX_PROFILE 512
struct qh_store { uint32_t keys[QH_MAX_HIDDEN]; size_t count; };
int qh_key_parse(const char *text, uint32_t *key);
int qh_store_has(const struct qh_store *store, uint32_t key);
int qh_store_set(struct qh_store *store, uint32_t key, int hidden);
int qh_store_decode(struct qh_store *store, const char *profile, const char *text);
int qh_store_encode(const struct qh_store *store, const char *profile, char *out, size_t capacity);
uint64_t qh_profile_hash(const char *profile);
/* Shared objective objects stay visible if any matching quest is visible. */
int qh_group_hidden(unsigned hidden, unsigned visible, unsigned unknown);
#endif
