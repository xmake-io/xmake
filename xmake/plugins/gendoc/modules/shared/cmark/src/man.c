#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cmark.h"
#include "node.h"
#include "buffer.h"
#include "utf8.h"
#include "render.h"

#define OUT(s, wrap, escaping) renderer->out(renderer, s, wrap, escaping)
#define LIT(s) renderer->out(renderer, s, false, LITERAL)
#define CR() renderer->cr(renderer)
#define BLANKLINE() renderer->blankline(renderer)
#define LIST_NUMBER_SIZE 20

// Functions to convert cmark_nodes to groff man strings.
static void S_outc(cmark_renderer *renderer, cmark_escaping escape, int32_t c,
                   unsigned char nextc) {
  (void)(nextc);

  if (escape == LITERAL) {
    cmark_render_code_point(renderer, c);
    return;
  }

  switch (c) {
  case 46:
    if (renderer->begin_line) {
      cmark_render_ascii(renderer, "\\&.");
    } else {
      cmark_render_code_point(renderer, c);
    }
    break;
  case 39:
    if (renderer->begin_line) {
      cmark_render_ascii(renderer, "\\&'");
    } else {
      cmark_render_code_point(renderer, c);
    }
    break;
  case 45:
    cmark_render_ascii(renderer, "\\-");
    break;
  case 92:
    cmark_render_ascii(renderer, "\\e");
    break;
  case 8216: // left single quote
    cmark_render_ascii(renderer, "\\[oq]");
    break;
  case 8217: // right single quote
    cmark_render_ascii(renderer, "\\[cq]");
    break;
  case 8220: // left double quote
    cmark_render_ascii(renderer, "\\[lq]");
    break;
  case 8221: // right double quote
    cmark_render_ascii(renderer, "\\[rq]");
    break;
  case 8212: // em dash
    cmark_render_ascii(renderer, "\\[em]");
    break;
  case 8211: // en dash
    cmark_render_ascii(renderer, "\\[en]");
    break;
  default:
    cmark_render_code_point(renderer, c);
  }
}

static int S_render_node(cmark_renderer *renderer, cmark_node *node,
                         cmark_event_type ev_type, int options) {
  cmark_node *tmp;
  int list_number;
  bool entering = (ev_type == CMARK_EVENT_ENTER);
  bool allow_wrap = renderer->width > 0 && !(CMARK_OPT_NOBREAKS & options);
  struct block_number *new_block_number;
  cmark_mem *allocator = cmark_get_default_mem_allocator();

  // avoid unused parameter error:
  (void)(options);

  // indent inside nested lists
  if (renderer->block_number_in_list_item &&
      node->type < CMARK_NODE_FIRST_INLINE) {
    if (entering) {
      renderer->block_number_in_list_item->number += 1;
      if (renderer->block_number_in_list_item->number == 2) {
        CR();
        LIT(".RS"); // indent
        CR();
      }
    }
  }

  switch (node->type) {
  case CMARK_NODE_DOCUMENT:
    break;

  case CMARK_NODE_BLOCK_QUOTE:
    if (entering) {
      CR();
      LIT(".RS");
      CR();
    } else {
      CR();
      LIT(".RE");
      CR();
    }
    break;

  case CMARK_NODE_LIST:
    break;

  case CMARK_NODE_ITEM:
    if (entering) {
      new_block_number = allocator->calloc(1, sizeof(struct block_number));
      new_block_number->number = 0;
      new_block_number->parent = renderer->block_number_in_list_item;
      renderer->block_number_in_list_item = new_block_number;
      CR();
      LIT(".IP ");
      if (cmark_node_get_list_type(node->parent) == CMARK_BULLET_LIST) {
        LIT("\\[bu] 2");
      } else {
        list_number = cmark_node_get_list_start(node->parent);
        tmp = node;
        while (tmp->prev) {
          tmp = tmp->prev;
          list_number += 1;
        }
        char list_number_s[LIST_NUMBER_SIZE];
        snprintf(list_number_s, LIST_NUMBER_SIZE, "\"%d.\" 4", list_number);
        LIT(list_number_s);
      }
      CR();
    } else {
      if (renderer->block_number_in_list_item) {
        if (renderer->block_number_in_list_item->number >= 2) {
          CR();
          LIT(".RE"); // de-indent
        }
        new_block_number = renderer->block_number_in_list_item;
        renderer->block_number_in_list_item =
          renderer->block_number_in_list_item->parent;
        allocator->free(new_block_number);
      }
      CR();
    }
    break;

  case CMARK_NODE_HEADING:
    if (entering) {
      CR();
      LIT(cmark_node_get_heading_level(node) == 1 ? ".SH" : ".SS");
      CR();
    } else {
      CR();
    }
    break;

  case CMARK_NODE_CODE_BLOCK:
    CR();
    LIT(".IP\n.nf\n\\f[C]\n");
    OUT(cmark_node_get_literal(node), false, NORMAL);
    CR();
    LIT("\\f[]\n.fi");
    CR();
    break;

  case CMARK_NODE_HTML_BLOCK:
    break;

  case CMARK_NODE_CUSTOM_BLOCK:
    CR();
    OUT(entering ? cmark_node_get_on_enter(node) : cmark_node_get_on_exit(node),
        false, LITERAL);
    CR();
    break;

  case CMARK_NODE_THEMATIC_BREAK:
    CR();
    LIT(".PP\n  *  *  *  *  *");
    CR();
    break;

  case CMARK_NODE_PARAGRAPH:
    if (entering) {
      // no blank line if first paragraph in list:
      if (node->parent && node->parent->type == CMARK_NODE_ITEM &&
          node->prev == NULL) {
        // no blank line or .PP
      } else {
        CR();
        LIT(".PP");
        CR();
      }
    } else {
      CR();
    }
    break;

  case CMARK_NODE_TEXT:
    OUT(cmark_node_get_literal(node), allow_wrap, NORMAL);
    break;

  case CMARK_NODE_LINEBREAK:
    LIT(".PD 0\n.P\n.PD");
    CR();
    break;

  case CMARK_NODE_SOFTBREAK:
    if (options & CMARK_OPT_HARDBREAKS) {
      LIT(".PD 0\n.P\n.PD");
      CR();
    } else if (renderer->width == 0 && !(CMARK_OPT_NOBREAKS & options)) {
      CR();
    } else {
      OUT(" ", allow_wrap, LITERAL);
    }
    break;

  case CMARK_NODE_CODE:
    LIT("\\f[C]");
    OUT(cmark_node_get_literal(node), allow_wrap, NORMAL);
    LIT("\\f[]");
    break;

  case CMARK_NODE_HTML_INLINE:
    break;

  case CMARK_NODE_CUSTOM_INLINE:
    OUT(entering ? cmark_node_get_on_enter(node) : cmark_node_get_on_exit(node),
        false, LITERAL);
    break;

  case CMARK_NODE_STRONG:
    if (entering) {
      LIT("\\f[B]");
    } else {
      LIT("\\f[]");
    }
    break;

  case CMARK_NODE_EMPH:
    if (entering) {
      LIT("\\f[I]");
    } else {
      LIT("\\f[]");
    }
    break;

  case CMARK_NODE_LINK:
    if (!entering) {
      LIT(" (");
      OUT(cmark_node_get_url(node), allow_wrap, URL);
      LIT(")");
    }
    break;

  case CMARK_NODE_IMAGE:
    if (entering) {
      LIT("[IMAGE: ");
    } else {
      LIT("]");
    }
    break;

  default:
    assert(false);
    break;
  }

  return 1;
}

char *cmark_render_man(cmark_node *root, int options, int width) {
  return cmark_render(root, options, width, S_outc, S_render_node);
}
