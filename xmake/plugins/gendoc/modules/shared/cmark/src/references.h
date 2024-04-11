#ifndef CMARK_REFERENCES_H
#define CMARK_REFERENCES_H

#include "chunk.h"

#ifdef __cplusplus
extern "C" {
#endif

struct cmark_reference {
  struct cmark_reference *next;
  unsigned char *label;
  unsigned char *url;
  unsigned char *title;
  unsigned int age;
  unsigned int size;
};

typedef struct cmark_reference cmark_reference;

struct cmark_reference_map {
  cmark_mem *mem;
  cmark_reference *refs;
  cmark_reference **sorted;
  unsigned int size;
  unsigned int ref_size;
  unsigned int max_ref_size;
};

typedef struct cmark_reference_map cmark_reference_map;

cmark_reference_map *cmark_reference_map_new(cmark_mem *mem);
void cmark_reference_map_free(cmark_reference_map *map);
cmark_reference *cmark_reference_lookup(cmark_reference_map *map,
                                        cmark_chunk *label);
extern void cmark_reference_create(cmark_reference_map *map, cmark_chunk *label,
                                   cmark_chunk *url, cmark_chunk *title);

#ifdef __cplusplus
}
#endif

#endif
