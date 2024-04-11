#include <assert.h>
#include <stdbool.h>
#include <stdlib.h>

#include "node.h"
#include "cmark.h"
#include "iterator.h"

static const int S_leaf_mask =
    (1 << CMARK_NODE_HTML_BLOCK) | (1 << CMARK_NODE_THEMATIC_BREAK) |
    (1 << CMARK_NODE_CODE_BLOCK) | (1 << CMARK_NODE_TEXT) |
    (1 << CMARK_NODE_SOFTBREAK) | (1 << CMARK_NODE_LINEBREAK) |
    (1 << CMARK_NODE_CODE) | (1 << CMARK_NODE_HTML_INLINE);

cmark_iter *cmark_iter_new(cmark_node *root) {
  if (root == NULL) {
    return NULL;
  }
  cmark_mem *mem = root->mem;
  cmark_iter *iter = (cmark_iter *)mem->calloc(1, sizeof(cmark_iter));
  iter->mem = mem;
  iter->root = root;
  iter->cur.ev_type = CMARK_EVENT_NONE;
  iter->cur.node = NULL;
  iter->next.ev_type = CMARK_EVENT_ENTER;
  iter->next.node = root;
  return iter;
}

void cmark_iter_free(cmark_iter *iter) { iter->mem->free(iter); }

static bool S_is_leaf(cmark_node *node) {
  return ((1 << node->type) & S_leaf_mask) != 0;
}

cmark_event_type cmark_iter_next(cmark_iter *iter) {
  cmark_event_type ev_type = iter->next.ev_type;
  cmark_node *node = iter->next.node;

  iter->cur.ev_type = ev_type;
  iter->cur.node = node;

  if (ev_type == CMARK_EVENT_DONE) {
    return ev_type;
  }

  /* roll forward to next item, setting both fields */
  if (ev_type == CMARK_EVENT_ENTER && !S_is_leaf(node)) {
    if (node->first_child == NULL) {
      /* stay on this node but exit */
      iter->next.ev_type = CMARK_EVENT_EXIT;
    } else {
      iter->next.ev_type = CMARK_EVENT_ENTER;
      iter->next.node = node->first_child;
    }
  } else if (node == iter->root) {
    /* don't move past root */
    iter->next.ev_type = CMARK_EVENT_DONE;
    iter->next.node = NULL;
  } else if (node->next) {
    iter->next.ev_type = CMARK_EVENT_ENTER;
    iter->next.node = node->next;
  } else if (node->parent) {
    iter->next.ev_type = CMARK_EVENT_EXIT;
    iter->next.node = node->parent;
  } else {
    assert(false);
    iter->next.ev_type = CMARK_EVENT_DONE;
    iter->next.node = NULL;
  }

  return ev_type;
}

void cmark_iter_reset(cmark_iter *iter, cmark_node *current,
                      cmark_event_type event_type) {
  iter->next.ev_type = event_type;
  iter->next.node = current;
  cmark_iter_next(iter);
}

cmark_node *cmark_iter_get_node(cmark_iter *iter) { return iter->cur.node; }

cmark_event_type cmark_iter_get_event_type(cmark_iter *iter) {
  return iter->cur.ev_type;
}

cmark_node *cmark_iter_get_root(cmark_iter *iter) { return iter->root; }

void cmark_consolidate_text_nodes(cmark_node *root) {
  if (root == NULL) {
    return;
  }
  cmark_iter *iter = cmark_iter_new(root);
  cmark_strbuf buf = CMARK_BUF_INIT(iter->mem);
  cmark_event_type ev_type;
  cmark_node *cur, *tmp, *next;

  while ((ev_type = cmark_iter_next(iter)) != CMARK_EVENT_DONE) {
    cur = cmark_iter_get_node(iter);
    if (ev_type == CMARK_EVENT_ENTER && cur->type == CMARK_NODE_TEXT &&
        cur->next && cur->next->type == CMARK_NODE_TEXT) {
      cmark_strbuf_clear(&buf);
      cmark_strbuf_put(&buf, cur->data, cur->len);
      tmp = cur->next;
      while (tmp && tmp->type == CMARK_NODE_TEXT) {
        cmark_iter_next(iter); // advance pointer
        cmark_strbuf_put(&buf, tmp->data, tmp->len);
        cur->end_column = tmp->end_column;
        next = tmp->next;
        cmark_node_free(tmp);
        tmp = next;
      }
      iter->mem->free(cur->data);
      cur->len = buf.size;
      cur->data = cmark_strbuf_detach(&buf);
    }
  }

  cmark_strbuf_free(&buf);
  cmark_iter_free(iter);
}
