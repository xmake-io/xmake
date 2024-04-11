#include "cmark.h"
#include "utf8.h"
#include "parser.h"
#include "references.h"
#include "inlines.h"
#include "chunk.h"

static void reference_free(cmark_reference_map *map, cmark_reference *ref) {
  cmark_mem *mem = map->mem;
  if (ref != NULL) {
    mem->free(ref->label);
    mem->free(ref->url);
    mem->free(ref->title);
    mem->free(ref);
  }
}

// normalize reference:  collapse internal whitespace to single space,
// remove leading/trailing whitespace, case fold
// Return NULL if the reference name is actually empty (i.e. composed
// solely from whitespace)
static unsigned char *normalize_reference(cmark_mem *mem, cmark_chunk *ref) {
  cmark_strbuf normalized = CMARK_BUF_INIT(mem);
  unsigned char *result;

  if (ref == NULL)
    return NULL;

  if (ref->len == 0)
    return NULL;

  cmark_utf8proc_case_fold(&normalized, ref->data, ref->len);
  cmark_strbuf_trim(&normalized);
  cmark_strbuf_normalize_whitespace(&normalized);

  result = cmark_strbuf_detach(&normalized);
  assert(result);

  if (result[0] == '\0') {
    mem->free(result);
    return NULL;
  }

  return result;
}

void cmark_reference_create(cmark_reference_map *map, cmark_chunk *label,
                            cmark_chunk *url, cmark_chunk *title) {
  cmark_reference *ref;
  unsigned char *reflabel = normalize_reference(map->mem, label);

  /* empty reference name, or composed from only whitespace */
  if (reflabel == NULL)
    return;

  assert(map->sorted == NULL);

  ref = (cmark_reference *)map->mem->calloc(1, sizeof(*ref));
  ref->label = reflabel;
  ref->url = cmark_clean_url(map->mem, url);
  ref->title = cmark_clean_title(map->mem, title);
  ref->age = map->size;
  ref->next = map->refs;

  if (ref->url != NULL)
    ref->size += (int)strlen((char*)ref->url);
  if (ref->title != NULL)
    ref->size += (int)strlen((char*)ref->title);

  map->refs = ref;
  map->size++;
}

static int
labelcmp(const unsigned char *a, const unsigned char *b) {
  return strcmp((const char *)a, (const char *)b);
}

static int
refcmp(const void *p1, const void *p2) {
  cmark_reference *r1 = *(cmark_reference **)p1;
  cmark_reference *r2 = *(cmark_reference **)p2;
  int res = labelcmp(r1->label, r2->label);
  return res ? res : ((int)r1->age - (int)r2->age);
}

static int
refsearch(const void *label, const void *p2) {
  cmark_reference *ref = *(cmark_reference **)p2;
  return labelcmp((const unsigned char *)label, ref->label);
}

static void sort_references(cmark_reference_map *map) {
  unsigned int i = 0, last = 0, size = map->size;
  cmark_reference *r = map->refs, **sorted = NULL;

  sorted = (cmark_reference **)map->mem->calloc(size, sizeof(cmark_reference *));
  while (r) {
    sorted[i++] = r;
    r = r->next;
  }

  qsort(sorted, size, sizeof(cmark_reference *), refcmp);

  for (i = 1; i < size; i++) {
    if (labelcmp(sorted[i]->label, sorted[last]->label) != 0)
      sorted[++last] = sorted[i];
  }
  map->sorted = sorted;
  map->size = last + 1;
}

// Returns reference if refmap contains a reference with matching
// label, otherwise NULL.
cmark_reference *cmark_reference_lookup(cmark_reference_map *map,
                                        cmark_chunk *label) {
  cmark_reference **ref = NULL;
  cmark_reference *r = NULL;
  unsigned char *norm;

  if (label->len < 1 || label->len > MAX_LINK_LABEL_LENGTH)
    return NULL;

  if (map == NULL || !map->size)
    return NULL;

  norm = normalize_reference(map->mem, label);
  if (norm == NULL)
    return NULL;

  if (!map->sorted)
    sort_references(map);

  ref = (cmark_reference **)bsearch(norm, map->sorted, map->size, sizeof(cmark_reference *),
                refsearch);
  map->mem->free(norm);

  if (ref != NULL) {
    r = ref[0];
    /* Check for expansion limit */
    if (map->max_ref_size && r->size > map->max_ref_size - map->ref_size)
      return NULL;
    map->ref_size += r->size;
  }

  return r;
}

void cmark_reference_map_free(cmark_reference_map *map) {
  cmark_reference *ref;

  if (map == NULL)
    return;

  ref = map->refs;
  while (ref) {
    cmark_reference *next = ref->next;
    reference_free(map, ref);
    ref = next;
  }

  map->mem->free(map->sorted);
  map->mem->free(map);
}

cmark_reference_map *cmark_reference_map_new(cmark_mem *mem) {
  cmark_reference_map *map =
      (cmark_reference_map *)mem->calloc(1, sizeof(cmark_reference_map));
  map->mem = mem;
  return map;
}
