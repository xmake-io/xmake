#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

#include "node.h"

static void S_node_unlink(cmark_node *node);

static inline bool S_is_block(cmark_node *node) {
  if (node == NULL) {
    return false;
  }
  return node->type >= CMARK_NODE_FIRST_BLOCK &&
         node->type <= CMARK_NODE_LAST_BLOCK;
}

static inline bool S_is_inline(cmark_node *node) {
  if (node == NULL) {
    return false;
  }
  return node->type >= CMARK_NODE_FIRST_INLINE &&
         node->type <= CMARK_NODE_LAST_INLINE;
}

static bool S_can_contain(cmark_node *node, cmark_node *child) {
  if (node == NULL || child == NULL || node == child) {
    return false;
  }

  // Verify that child is not an ancestor of node.
  if (child->first_child != NULL) {
    cmark_node *cur = node->parent;

    while (cur != NULL) {
      if (cur == child) {
        return false;
      }
      cur = cur->parent;
    }
  }

  if (child->type == CMARK_NODE_DOCUMENT) {
    return false;
  }

  switch (node->type) {
  case CMARK_NODE_DOCUMENT:
  case CMARK_NODE_BLOCK_QUOTE:
  case CMARK_NODE_ITEM:
    return S_is_block(child) && child->type != CMARK_NODE_ITEM;

  case CMARK_NODE_LIST:
    return child->type == CMARK_NODE_ITEM;

  case CMARK_NODE_CUSTOM_BLOCK:
    return true;

  case CMARK_NODE_PARAGRAPH:
  case CMARK_NODE_HEADING:
  case CMARK_NODE_EMPH:
  case CMARK_NODE_STRONG:
  case CMARK_NODE_LINK:
  case CMARK_NODE_IMAGE:
  case CMARK_NODE_CUSTOM_INLINE:
    return S_is_inline(child);

  default:
    break;
  }

  return false;
}

cmark_node *cmark_node_new_with_mem(cmark_node_type type, cmark_mem *mem) {
  cmark_node *node = (cmark_node *)mem->calloc(1, sizeof(*node));
  node->mem = mem;
  node->type = (uint16_t)type;

  switch (node->type) {
  case CMARK_NODE_HEADING:
    node->as.heading.level = 1;
    break;

  case CMARK_NODE_LIST: {
    cmark_list *list = &node->as.list;
    list->list_type = CMARK_BULLET_LIST;
    list->start = 0;
    list->tight = false;
    break;
  }

  default:
    break;
  }

  return node;
}

cmark_node *cmark_node_new(cmark_node_type type) {
  extern cmark_mem DEFAULT_MEM_ALLOCATOR;
  return cmark_node_new_with_mem(type, &DEFAULT_MEM_ALLOCATOR);
}

// Free a cmark_node list and any children.
static void S_free_nodes(cmark_node *e) {
  cmark_mem *mem = e->mem;
  cmark_node *next;
  while (e != NULL) {
    switch (e->type) {
    case CMARK_NODE_CODE_BLOCK:
      mem->free(e->data);
      mem->free(e->as.code.info);
      break;
    case CMARK_NODE_TEXT:
    case CMARK_NODE_HTML_INLINE:
    case CMARK_NODE_CODE:
    case CMARK_NODE_HTML_BLOCK:
      mem->free(e->data);
      break;
    case CMARK_NODE_LINK:
    case CMARK_NODE_IMAGE:
      mem->free(e->as.link.url);
      mem->free(e->as.link.title);
      break;
    case CMARK_NODE_CUSTOM_BLOCK:
    case CMARK_NODE_CUSTOM_INLINE:
      mem->free(e->as.custom.on_enter);
      mem->free(e->as.custom.on_exit);
      break;
    default:
      break;
    }
    if (e->last_child) {
      // Splice children into list
      e->last_child->next = e->next;
      e->next = e->first_child;
    }
    next = e->next;
    mem->free(e);
    e = next;
  }
}

void cmark_node_free(cmark_node *node) {
  S_node_unlink(node);
  node->next = NULL;
  S_free_nodes(node);
}

cmark_node_type cmark_node_get_type(cmark_node *node) {
  if (node == NULL) {
    return CMARK_NODE_NONE;
  } else {
    return (cmark_node_type)node->type;
  }
}

const char *cmark_node_get_type_string(cmark_node *node) {
  if (node == NULL) {
    return "NONE";
  }

  switch (node->type) {
  case CMARK_NODE_NONE:
    return "none";
  case CMARK_NODE_DOCUMENT:
    return "document";
  case CMARK_NODE_BLOCK_QUOTE:
    return "block_quote";
  case CMARK_NODE_LIST:
    return "list";
  case CMARK_NODE_ITEM:
    return "item";
  case CMARK_NODE_CODE_BLOCK:
    return "code_block";
  case CMARK_NODE_HTML_BLOCK:
    return "html_block";
  case CMARK_NODE_CUSTOM_BLOCK:
    return "custom_block";
  case CMARK_NODE_PARAGRAPH:
    return "paragraph";
  case CMARK_NODE_HEADING:
    return "heading";
  case CMARK_NODE_THEMATIC_BREAK:
    return "thematic_break";
  case CMARK_NODE_TEXT:
    return "text";
  case CMARK_NODE_SOFTBREAK:
    return "softbreak";
  case CMARK_NODE_LINEBREAK:
    return "linebreak";
  case CMARK_NODE_CODE:
    return "code";
  case CMARK_NODE_HTML_INLINE:
    return "html_inline";
  case CMARK_NODE_CUSTOM_INLINE:
    return "custom_inline";
  case CMARK_NODE_EMPH:
    return "emph";
  case CMARK_NODE_STRONG:
    return "strong";
  case CMARK_NODE_LINK:
    return "link";
  case CMARK_NODE_IMAGE:
    return "image";
  }

  return "<unknown>";
}

cmark_node *cmark_node_next(cmark_node *node) {
  if (node == NULL) {
    return NULL;
  } else {
    return node->next;
  }
}

cmark_node *cmark_node_previous(cmark_node *node) {
  if (node == NULL) {
    return NULL;
  } else {
    return node->prev;
  }
}

cmark_node *cmark_node_parent(cmark_node *node) {
  if (node == NULL) {
    return NULL;
  } else {
    return node->parent;
  }
}

cmark_node *cmark_node_first_child(cmark_node *node) {
  if (node == NULL) {
    return NULL;
  } else {
    return node->first_child;
  }
}

cmark_node *cmark_node_last_child(cmark_node *node) {
  if (node == NULL) {
    return NULL;
  } else {
    return node->last_child;
  }
}

static bufsize_t cmark_set_cstr(cmark_mem *mem, unsigned char **dst,
                                const char *src) {
  unsigned char *old = *dst;
  bufsize_t len;

  if (src && src[0]) {
      len = (bufsize_t)strlen(src);
      *dst = (unsigned char *)mem->realloc(NULL, len + 1);
      memcpy(*dst, src, len + 1);
  } else {
      len = 0;
      *dst = NULL;
  }
  if (old) {
    mem->free(old);
  }

  return len;
}

void *cmark_node_get_user_data(cmark_node *node) {
  if (node == NULL) {
    return NULL;
  } else {
    return node->user_data;
  }
}

int cmark_node_set_user_data(cmark_node *node, void *user_data) {
  if (node == NULL) {
    return 0;
  }
  node->user_data = user_data;
  return 1;
}

const char *cmark_node_get_literal(cmark_node *node) {
  if (node == NULL) {
    return NULL;
  }

  switch (node->type) {
  case CMARK_NODE_HTML_BLOCK:
  case CMARK_NODE_TEXT:
  case CMARK_NODE_HTML_INLINE:
  case CMARK_NODE_CODE:
  case CMARK_NODE_CODE_BLOCK:
    return node->data ? (char *)node->data : "";

  default:
    break;
  }

  return NULL;
}

int cmark_node_set_literal(cmark_node *node, const char *content) {
  if (node == NULL) {
    return 0;
  }

  switch (node->type) {
  case CMARK_NODE_HTML_BLOCK:
  case CMARK_NODE_TEXT:
  case CMARK_NODE_HTML_INLINE:
  case CMARK_NODE_CODE:
  case CMARK_NODE_CODE_BLOCK:
    node->len = cmark_set_cstr(node->mem, &node->data, content);
    return 1;

  default:
    break;
  }

  return 0;
}

int cmark_node_get_heading_level(cmark_node *node) {
  if (node == NULL) {
    return 0;
  }

  switch (node->type) {
  case CMARK_NODE_HEADING:
    return node->as.heading.level;

  default:
    break;
  }

  return 0;
}

int cmark_node_set_heading_level(cmark_node *node, int level) {
  if (node == NULL || level < 1 || level > 6) {
    return 0;
  }

  switch (node->type) {
  case CMARK_NODE_HEADING:
    node->as.heading.level = level;
    return 1;

  default:
    break;
  }

  return 0;
}

cmark_list_type cmark_node_get_list_type(cmark_node *node) {
  if (node == NULL) {
    return CMARK_NO_LIST;
  }

  if (node->type == CMARK_NODE_LIST) {
    return (cmark_list_type)node->as.list.list_type;
  } else {
    return CMARK_NO_LIST;
  }
}

int cmark_node_set_list_type(cmark_node *node, cmark_list_type type) {
  if (!(type == CMARK_BULLET_LIST || type == CMARK_ORDERED_LIST)) {
    return 0;
  }

  if (node == NULL) {
    return 0;
  }

  if (node->type == CMARK_NODE_LIST) {
    node->as.list.list_type = (unsigned char)type;
    return 1;
  } else {
    return 0;
  }
}

cmark_delim_type cmark_node_get_list_delim(cmark_node *node) {
  if (node == NULL) {
    return CMARK_NO_DELIM;
  }

  if (node->type == CMARK_NODE_LIST) {
    return (cmark_delim_type)node->as.list.delimiter;
  } else {
    return CMARK_NO_DELIM;
  }
}

int cmark_node_set_list_delim(cmark_node *node, cmark_delim_type delim) {
  if (!(delim == CMARK_PERIOD_DELIM || delim == CMARK_PAREN_DELIM)) {
    return 0;
  }

  if (node == NULL) {
    return 0;
  }

  if (node->type == CMARK_NODE_LIST) {
    node->as.list.delimiter = (unsigned char)delim;
    return 1;
  } else {
    return 0;
  }
}

int cmark_node_get_list_start(cmark_node *node) {
  if (node == NULL) {
    return 0;
  }

  if (node->type == CMARK_NODE_LIST) {
    return node->as.list.start;
  } else {
    return 0;
  }
}

int cmark_node_set_list_start(cmark_node *node, int start) {
  if (node == NULL || start < 0) {
    return 0;
  }

  if (node->type == CMARK_NODE_LIST) {
    node->as.list.start = start;
    return 1;
  } else {
    return 0;
  }
}

int cmark_node_get_list_tight(cmark_node *node) {
  if (node == NULL) {
    return 0;
  }

  if (node->type == CMARK_NODE_LIST) {
    return node->as.list.tight;
  } else {
    return 0;
  }
}

int cmark_node_set_list_tight(cmark_node *node, int tight) {
  if (node == NULL) {
    return 0;
  }

  if (node->type == CMARK_NODE_LIST) {
    node->as.list.tight = tight == 1;
    return 1;
  } else {
    return 0;
  }
}

const char *cmark_node_get_fence_info(cmark_node *node) {
  if (node == NULL) {
    return NULL;
  }

  if (node->type == CMARK_NODE_CODE_BLOCK) {
    return node->as.code.info ? (char *)node->as.code.info : "";
  } else {
    return NULL;
  }
}

int cmark_node_set_fence_info(cmark_node *node, const char *info) {
  if (node == NULL) {
    return 0;
  }

  if (node->type == CMARK_NODE_CODE_BLOCK) {
    cmark_set_cstr(node->mem, &node->as.code.info, info);
    return 1;
  } else {
    return 0;
  }
}

const char *cmark_node_get_url(cmark_node *node) {
  if (node == NULL) {
    return NULL;
  }

  switch (node->type) {
  case CMARK_NODE_LINK:
  case CMARK_NODE_IMAGE:
    return node->as.link.url ? (char *)node->as.link.url : "";
  default:
    break;
  }

  return NULL;
}

int cmark_node_set_url(cmark_node *node, const char *url) {
  if (node == NULL) {
    return 0;
  }

  switch (node->type) {
  case CMARK_NODE_LINK:
  case CMARK_NODE_IMAGE:
    cmark_set_cstr(node->mem, &node->as.link.url, url);
    return 1;
  default:
    break;
  }

  return 0;
}

const char *cmark_node_get_title(cmark_node *node) {
  if (node == NULL) {
    return NULL;
  }

  switch (node->type) {
  case CMARK_NODE_LINK:
  case CMARK_NODE_IMAGE:
    return node->as.link.title ? (char *)node->as.link.title : "";
  default:
    break;
  }

  return NULL;
}

int cmark_node_set_title(cmark_node *node, const char *title) {
  if (node == NULL) {
    return 0;
  }

  switch (node->type) {
  case CMARK_NODE_LINK:
  case CMARK_NODE_IMAGE:
    cmark_set_cstr(node->mem, &node->as.link.title, title);
    return 1;
  default:
    break;
  }

  return 0;
}

const char *cmark_node_get_on_enter(cmark_node *node) {
  if (node == NULL) {
    return NULL;
  }

  switch (node->type) {
  case CMARK_NODE_CUSTOM_INLINE:
  case CMARK_NODE_CUSTOM_BLOCK:
    return node->as.custom.on_enter ? (char *)node->as.custom.on_enter : "";
  default:
    break;
  }

  return NULL;
}

int cmark_node_set_on_enter(cmark_node *node, const char *on_enter) {
  if (node == NULL) {
    return 0;
  }

  switch (node->type) {
  case CMARK_NODE_CUSTOM_INLINE:
  case CMARK_NODE_CUSTOM_BLOCK:
    cmark_set_cstr(node->mem, &node->as.custom.on_enter, on_enter);
    return 1;
  default:
    break;
  }

  return 0;
}

const char *cmark_node_get_on_exit(cmark_node *node) {
  if (node == NULL) {
    return NULL;
  }

  switch (node->type) {
  case CMARK_NODE_CUSTOM_INLINE:
  case CMARK_NODE_CUSTOM_BLOCK:
    return node->as.custom.on_exit ? (char *)node->as.custom.on_exit : "";
  default:
    break;
  }

  return NULL;
}

int cmark_node_set_on_exit(cmark_node *node, const char *on_exit) {
  if (node == NULL) {
    return 0;
  }

  switch (node->type) {
  case CMARK_NODE_CUSTOM_INLINE:
  case CMARK_NODE_CUSTOM_BLOCK:
    cmark_set_cstr(node->mem, &node->as.custom.on_exit, on_exit);
    return 1;
  default:
    break;
  }

  return 0;
}

int cmark_node_get_start_line(cmark_node *node) {
  if (node == NULL) {
    return 0;
  }
  return node->start_line;
}

int cmark_node_get_start_column(cmark_node *node) {
  if (node == NULL) {
    return 0;
  }
  return node->start_column;
}

int cmark_node_get_end_line(cmark_node *node) {
  if (node == NULL) {
    return 0;
  }
  return node->end_line;
}

int cmark_node_get_end_column(cmark_node *node) {
  if (node == NULL) {
    return 0;
  }
  return node->end_column;
}

// Unlink a node without adjusting its next, prev, and parent pointers.
static void S_node_unlink(cmark_node *node) {
  if (node == NULL) {
    return;
  }

  if (node->prev) {
    node->prev->next = node->next;
  }
  if (node->next) {
    node->next->prev = node->prev;
  }

  // Adjust first_child and last_child of parent.
  cmark_node *parent = node->parent;
  if (parent) {
    if (parent->first_child == node) {
      parent->first_child = node->next;
    }
    if (parent->last_child == node) {
      parent->last_child = node->prev;
    }
  }
}

void cmark_node_unlink(cmark_node *node) {
  S_node_unlink(node);

  node->next = NULL;
  node->prev = NULL;
  node->parent = NULL;
}

int cmark_node_insert_before(cmark_node *node, cmark_node *sibling) {
  if (node == NULL || sibling == NULL) {
    return 0;
  }

  if (!node->parent || !S_can_contain(node->parent, sibling)) {
    return 0;
  }

  S_node_unlink(sibling);

  cmark_node *old_prev = node->prev;

  // Insert 'sibling' between 'old_prev' and 'node'.
  if (old_prev) {
    old_prev->next = sibling;
  }
  sibling->prev = old_prev;
  sibling->next = node;
  node->prev = sibling;

  // Set new parent.
  cmark_node *parent = node->parent;
  sibling->parent = parent;

  // Adjust first_child of parent if inserted as first child.
  if (parent && !old_prev) {
    parent->first_child = sibling;
  }

  return 1;
}

int cmark_node_insert_after(cmark_node *node, cmark_node *sibling) {
  if (node == NULL || sibling == NULL) {
    return 0;
  }

  if (!node->parent || !S_can_contain(node->parent, sibling)) {
    return 0;
  }

  S_node_unlink(sibling);

  cmark_node *old_next = node->next;

  // Insert 'sibling' between 'node' and 'old_next'.
  if (old_next) {
    old_next->prev = sibling;
  }
  sibling->next = old_next;
  sibling->prev = node;
  node->next = sibling;

  // Set new parent.
  cmark_node *parent = node->parent;
  sibling->parent = parent;

  // Adjust last_child of parent if inserted as last child.
  if (parent && !old_next) {
    parent->last_child = sibling;
  }

  return 1;
}

int cmark_node_replace(cmark_node *oldnode, cmark_node *newnode) {
  if (!cmark_node_insert_before(oldnode, newnode)) {
    return 0;
  }
  cmark_node_unlink(oldnode);
  return 1;
}

int cmark_node_prepend_child(cmark_node *node, cmark_node *child) {
  if (!S_can_contain(node, child)) {
    return 0;
  }

  S_node_unlink(child);

  cmark_node *old_first_child = node->first_child;

  child->next = old_first_child;
  child->prev = NULL;
  child->parent = node;
  node->first_child = child;

  if (old_first_child) {
    old_first_child->prev = child;
  } else {
    // Also set last_child if node previously had no children.
    node->last_child = child;
  }

  return 1;
}

int cmark_node_append_child(cmark_node *node, cmark_node *child) {
  if (!S_can_contain(node, child)) {
    return 0;
  }

  S_node_unlink(child);

  cmark_node *old_last_child = node->last_child;

  child->next = NULL;
  child->prev = old_last_child;
  child->parent = node;
  node->last_child = child;

  if (old_last_child) {
    old_last_child->next = child;
  } else {
    // Also set first_child if node previously had no children.
    node->first_child = child;
  }

  return 1;
}

static void S_print_error(FILE *out, cmark_node *node, const char *elem) {
  if (out == NULL) {
    return;
  }
  fprintf(out, "Invalid '%s' in node type %s at %d:%d\n", elem,
          cmark_node_get_type_string(node), node->start_line,
          node->start_column);
}

int cmark_node_check(cmark_node *node, FILE *out) {
  cmark_node *cur;
  int errors = 0;

  if (!node) {
    return 0;
  }

  cur = node;
  for (;;) {
    if (cur->first_child) {
      if (cur->first_child->prev != NULL) {
        S_print_error(out, cur->first_child, "prev");
        cur->first_child->prev = NULL;
        ++errors;
      }
      if (cur->first_child->parent != cur) {
        S_print_error(out, cur->first_child, "parent");
        cur->first_child->parent = cur;
        ++errors;
      }
      cur = cur->first_child;
      continue;
    }

  next_sibling:
    if (cur == node) {
      break;
    }
    if (cur->next) {
      if (cur->next->prev != cur) {
        S_print_error(out, cur->next, "prev");
        cur->next->prev = cur;
        ++errors;
      }
      if (cur->next->parent != cur->parent) {
        S_print_error(out, cur->next, "parent");
        cur->next->parent = cur->parent;
        ++errors;
      }
      cur = cur->next;
      continue;
    }

    if (cur->parent->last_child != cur) {
      S_print_error(out, cur->parent, "last_child");
      cur->parent->last_child = cur;
      ++errors;
    }
    cur = cur->parent;
    goto next_sibling;
  }

  return errors;
}
