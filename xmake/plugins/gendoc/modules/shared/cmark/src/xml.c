#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cmark.h"
#include "node.h"
#include "buffer.h"

#define BUFFER_SIZE 100
#define MAX_INDENT 40

// Functions to convert cmark_nodes to XML strings.

// C0 control characters, U+FFFE and U+FFF aren't allowed in XML.
static const char XML_ESCAPE_TABLE[256] = {
    /* 0x00 */ 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 1,
    /* 0x10 */ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    /* 0x20 */ 0, 0, 2, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    /* 0x30 */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 5, 0,
    /* 0x40 */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    /* 0x50 */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    /* 0x60 */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    /* 0x70 */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    /* 0x80 */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    /* 0x90 */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    /* 0xA0 */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    /* 0xB0 */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 9,
    /* 0xC0 */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    /* 0xD0 */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    /* 0xE0 */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    /* 0xF0 */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
};

// U+FFFD Replacement Character encoded in UTF-8
#define UTF8_REPL "\xEF\xBF\xBD"

static const char *XML_ESCAPES[] = {
  "", UTF8_REPL, "&quot;", "&amp;", "&lt;", "&gt;"
};

static void escape_xml(cmark_strbuf *ob, const unsigned char *src,
                       bufsize_t size) {
  bufsize_t i = 0, org, esc = 0;

  while (i < size) {
    org = i;
    while (i < size && (esc = XML_ESCAPE_TABLE[src[i]]) == 0)
      i++;

    if (i > org)
      cmark_strbuf_put(ob, src + org, i - org);

    if (i >= size)
      break;

    if (esc == 9) {
      // To replace U+FFFE and U+FFFF with U+FFFD, only the last byte has to
      // be changed.
      // We know that src[i] is 0xBE or 0xBF.
      if (i >= 2 && src[i-2] == 0xEF && src[i-1] == 0xBF) {
        cmark_strbuf_putc(ob, 0xBD);
      } else {
        cmark_strbuf_putc(ob, src[i]);
      }
    } else {
      cmark_strbuf_puts(ob, XML_ESCAPES[esc]);
    }

    i++;
  }
}

static void escape_xml_str(cmark_strbuf *dest, const unsigned char *source) {
  if (source)
    escape_xml(dest, source, (bufsize_t)strlen((char *)source));
}

struct render_state {
  cmark_strbuf *xml;
  int indent;
};

static inline void indent(struct render_state *state) {
  int i;
  for (i = 0; i < state->indent && i < MAX_INDENT; i++) {
    cmark_strbuf_putc(state->xml, ' ');
  }
}

static int S_render_node(cmark_node *node, cmark_event_type ev_type,
                         struct render_state *state, int options) {
  cmark_strbuf *xml = state->xml;
  bool literal = false;
  cmark_delim_type delim;
  bool entering = (ev_type == CMARK_EVENT_ENTER);
  char buffer[BUFFER_SIZE];

  if (entering) {
    indent(state);
    cmark_strbuf_putc(xml, '<');
    cmark_strbuf_puts(xml, cmark_node_get_type_string(node));

    if (options & CMARK_OPT_SOURCEPOS && node->start_line != 0) {
      snprintf(buffer, BUFFER_SIZE, " sourcepos=\"%d:%d-%d:%d\"",
               node->start_line, node->start_column, node->end_line,
               node->end_column);
      cmark_strbuf_puts(xml, buffer);
    }

    literal = false;

    switch (node->type) {
    case CMARK_NODE_DOCUMENT:
      cmark_strbuf_puts(xml, " xmlns=\"http://commonmark.org/xml/1.0\"");
      break;
    case CMARK_NODE_TEXT:
    case CMARK_NODE_CODE:
    case CMARK_NODE_HTML_BLOCK:
    case CMARK_NODE_HTML_INLINE:
      cmark_strbuf_puts(xml, " xml:space=\"preserve\">");
      escape_xml(xml, node->data, node->len);
      cmark_strbuf_puts(xml, "</");
      cmark_strbuf_puts(xml, cmark_node_get_type_string(node));
      literal = true;
      break;
    case CMARK_NODE_LIST:
      switch (cmark_node_get_list_type(node)) {
      case CMARK_ORDERED_LIST:
        cmark_strbuf_puts(xml, " type=\"ordered\"");
        snprintf(buffer, BUFFER_SIZE, " start=\"%d\"",
                 cmark_node_get_list_start(node));
        cmark_strbuf_puts(xml, buffer);
        delim = cmark_node_get_list_delim(node);
        if (delim == CMARK_PAREN_DELIM) {
          cmark_strbuf_puts(xml, " delim=\"paren\"");
        } else if (delim == CMARK_PERIOD_DELIM) {
          cmark_strbuf_puts(xml, " delim=\"period\"");
        }
        break;
      case CMARK_BULLET_LIST:
        cmark_strbuf_puts(xml, " type=\"bullet\"");
        break;
      default:
        break;
      }
      snprintf(buffer, BUFFER_SIZE, " tight=\"%s\"",
               (cmark_node_get_list_tight(node) ? "true" : "false"));
      cmark_strbuf_puts(xml, buffer);
      break;
    case CMARK_NODE_HEADING:
      snprintf(buffer, BUFFER_SIZE, " level=\"%d\"", node->as.heading.level);
      cmark_strbuf_puts(xml, buffer);
      break;
    case CMARK_NODE_CODE_BLOCK:
      if (node->as.code.info) {
        cmark_strbuf_puts(xml, " info=\"");
        escape_xml_str(xml, node->as.code.info);
        cmark_strbuf_putc(xml, '"');
      }
      cmark_strbuf_puts(xml, " xml:space=\"preserve\">");
      escape_xml(xml, node->data, node->len);
      cmark_strbuf_puts(xml, "</");
      cmark_strbuf_puts(xml, cmark_node_get_type_string(node));
      literal = true;
      break;
    case CMARK_NODE_CUSTOM_BLOCK:
    case CMARK_NODE_CUSTOM_INLINE:
      cmark_strbuf_puts(xml, " on_enter=\"");
      escape_xml_str(xml, node->as.custom.on_enter);
      cmark_strbuf_putc(xml, '"');
      cmark_strbuf_puts(xml, " on_exit=\"");
      escape_xml_str(xml, node->as.custom.on_exit);
      cmark_strbuf_putc(xml, '"');
      break;
    case CMARK_NODE_LINK:
    case CMARK_NODE_IMAGE:
      cmark_strbuf_puts(xml, " destination=\"");
      escape_xml_str(xml, node->as.link.url);
      cmark_strbuf_putc(xml, '"');
      if (node->as.link.title) {
        cmark_strbuf_puts(xml, " title=\"");
        escape_xml_str(xml, node->as.link.title);
        cmark_strbuf_putc(xml, '"');
      }
      break;
    default:
      break;
    }
    if (node->first_child) {
      state->indent += 2;
    } else if (!literal) {
      cmark_strbuf_puts(xml, " /");
    }
    cmark_strbuf_puts(xml, ">\n");

  } else if (node->first_child) {
    state->indent -= 2;
    indent(state);
    cmark_strbuf_puts(xml, "</");
    cmark_strbuf_puts(xml, cmark_node_get_type_string(node));
    cmark_strbuf_puts(xml, ">\n");
  }

  return 1;
}

char *cmark_render_xml(cmark_node *root, int options) {
  char *result;
  cmark_strbuf xml = CMARK_BUF_INIT(root->mem);
  cmark_event_type ev_type;
  cmark_node *cur;
  struct render_state state = {&xml, 0};

  cmark_iter *iter = cmark_iter_new(root);

  cmark_strbuf_puts(state.xml, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
  cmark_strbuf_puts(state.xml,
                    "<!DOCTYPE document SYSTEM \"CommonMark.dtd\">\n");
  while ((ev_type = cmark_iter_next(iter)) != CMARK_EVENT_DONE) {
    cur = cmark_iter_get_node(iter);
    S_render_node(cur, ev_type, &state, options);
  }
  result = (char *)cmark_strbuf_detach(&xml);

  cmark_iter_free(iter);
  return result;
}
