#ifndef CMARK_CHUNK_H
#define CMARK_CHUNK_H

#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include "cmark.h"
#include "buffer.h"
#include "cmark_ctype.h"

#define CMARK_CHUNK_EMPTY                                                      \
  { NULL, 0 }

typedef struct {
  const unsigned char *data;
  bufsize_t len;
} cmark_chunk;

// NOLINTNEXTLINE(clang-diagnostic-unused-function)
static inline void cmark_chunk_free(cmark_chunk *c) {
  c->data = NULL;
  c->len = 0;
}

static inline void cmark_chunk_ltrim(cmark_chunk *c) {
  while (c->len && cmark_isspace(c->data[0])) {
    c->data++;
    c->len--;
  }
}

static inline void cmark_chunk_rtrim(cmark_chunk *c) {
  while (c->len > 0) {
    if (!cmark_isspace(c->data[c->len - 1]))
      break;

    c->len--;
  }
}

// NOLINTNEXTLINE(clang-diagnostic-unused-function)
static inline void cmark_chunk_trim(cmark_chunk *c) {
  cmark_chunk_ltrim(c);
  cmark_chunk_rtrim(c);
}

// NOLINTNEXTLINE(clang-diagnostic-unused-function)
static inline bufsize_t cmark_chunk_strchr(cmark_chunk *ch, int c,
                                           bufsize_t offset) {
  const unsigned char *p =
      (unsigned char *)memchr(ch->data + offset, c, ch->len - offset);
  return p ? (bufsize_t)(p - ch->data) : ch->len;
}

// NOLINTNEXTLINE(clang-diagnostic-unused-function)
static inline cmark_chunk cmark_chunk_literal(const char *data) {
  bufsize_t len = data ? (bufsize_t)strlen(data) : 0;
  cmark_chunk c = {(unsigned char *)data, len};
  return c;
}

// NOLINTNEXTLINE(clang-diagnostic-unused-function)
static inline cmark_chunk cmark_chunk_dup(const cmark_chunk *ch, bufsize_t pos,
                                          bufsize_t len) {
  cmark_chunk c = {ch->data + pos, len};
  return c;
}

#endif
