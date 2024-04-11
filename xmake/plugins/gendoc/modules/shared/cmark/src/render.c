#include <stdlib.h>
#include "buffer.h"
#include "cmark.h"
#include "utf8.h"
#include "render.h"
#include "node.h"
#include "cmark_ctype.h"

static inline void S_cr(cmark_renderer *renderer) {
  if (renderer->need_cr < 1) {
    renderer->need_cr = 1;
  }
}

static inline void S_blankline(cmark_renderer *renderer) {
  if (renderer->need_cr < 2) {
    renderer->need_cr = 2;
  }
}

static void S_out(cmark_renderer *renderer, const char *source, bool wrap,
                  cmark_escaping escape) {
  int length = (int)strlen(source);
  unsigned char nextc;
  int32_t c;
  int i = 0;
  int last_nonspace;
  int len;
  int k = renderer->buffer->size - 1;

  wrap = wrap && !renderer->no_linebreaks;

  if (renderer->in_tight_list_item && renderer->need_cr > 1) {
    renderer->need_cr = 1;
  }
  while (renderer->need_cr) {
    if (k < 0 || renderer->buffer->ptr[k] == '\n') {
      k -= 1;
    } else {
      cmark_strbuf_putc(renderer->buffer, '\n');
      if (renderer->need_cr > 1) {
        cmark_strbuf_put(renderer->buffer, renderer->prefix->ptr,
                         renderer->prefix->size);
      }
    }
    renderer->column = 0;
    renderer->last_breakable = 0;
    renderer->begin_line = true;
    renderer->begin_content = true;
    renderer->need_cr -= 1;
  }

  while (i < length) {
    if (renderer->begin_line) {
      cmark_strbuf_put(renderer->buffer, renderer->prefix->ptr,
                       renderer->prefix->size);
      // note: this assumes prefix is ascii:
      renderer->column = renderer->prefix->size;
    }

    len = cmark_utf8proc_iterate((const uint8_t *)source + i, length - i, &c);
    if (len == -1) { // error condition
      return;        // return without rendering rest of string
    }
    nextc = source[i + len];
    if (c == 32 && wrap) {
      if (!renderer->begin_line) {
        last_nonspace = renderer->buffer->size;
        cmark_strbuf_putc(renderer->buffer, ' ');
        renderer->column += 1;
        renderer->begin_line = false;
        renderer->begin_content = false;
        // skip following spaces
        while (source[i + 1] == ' ') {
          i++;
        }
        // We don't allow breaks that make a digit the first character
        // because this causes problems with commonmark output.
        if (!cmark_isdigit(source[i + 1])) {
          renderer->last_breakable = last_nonspace;
        }
      }

    } else if (escape == LITERAL) {
      if (c == 10) {
        cmark_strbuf_putc(renderer->buffer, '\n');
        renderer->column = 0;
        renderer->begin_line = true;
        renderer->begin_content = true;
        renderer->last_breakable = 0;
      } else {
        cmark_render_code_point(renderer, c);
        renderer->begin_line = false;
        // we don't set 'begin_content' to false til we've
        // finished parsing a digit.  Reason:  in commonmark
        // we need to escape a potential list marker after
        // a digit:
        renderer->begin_content =
            renderer->begin_content && cmark_isdigit(c) == 1;
      }
    } else {
      (renderer->outc)(renderer, escape, c, nextc);
      renderer->begin_line = false;
      renderer->begin_content =
          renderer->begin_content && cmark_isdigit(c) == 1;
    }

    // If adding the character went beyond width, look for an
    // earlier place where the line could be broken:
    if (renderer->width > 0 && renderer->column > renderer->width &&
        !renderer->begin_line && renderer->last_breakable > 0) {

      // copy from last_breakable to remainder
      unsigned char *src = renderer->buffer->ptr +
                           renderer->last_breakable + 1;
      bufsize_t remainder_len = renderer->buffer->size -
                                renderer->last_breakable - 1;
      unsigned char *remainder =
          (unsigned char *)renderer->mem->realloc(NULL, remainder_len);
      memcpy(remainder, src, remainder_len);
      // truncate at last_breakable
      cmark_strbuf_truncate(renderer->buffer, renderer->last_breakable);
      // add newline, prefix, and remainder
      cmark_strbuf_putc(renderer->buffer, '\n');
      cmark_strbuf_put(renderer->buffer, renderer->prefix->ptr,
                       renderer->prefix->size);
      cmark_strbuf_put(renderer->buffer, remainder, remainder_len);
      renderer->column = renderer->prefix->size + remainder_len;
      renderer->mem->free(remainder);
      renderer->last_breakable = 0;
      renderer->begin_line = false;
      renderer->begin_content = false;
    }

    i += len;
  }
}

// Assumes no newlines, assumes ascii content:
void cmark_render_ascii(cmark_renderer *renderer, const char *s) {
  int origsize = renderer->buffer->size;
  cmark_strbuf_puts(renderer->buffer, s);
  renderer->column += renderer->buffer->size - origsize;
}

void cmark_render_code_point(cmark_renderer *renderer, uint32_t c) {
  cmark_utf8proc_encode_char(c, renderer->buffer);
  renderer->column += 1;
}

char *cmark_render(cmark_node *root, int options, int width,
                   void (*outc)(cmark_renderer *, cmark_escaping, int32_t,
                                unsigned char),
                   int (*render_node)(cmark_renderer *renderer,
                                      cmark_node *node,
                                      cmark_event_type ev_type, int options)) {
  cmark_mem *mem = root->mem;
  cmark_strbuf pref = CMARK_BUF_INIT(mem);
  cmark_strbuf buf = CMARK_BUF_INIT(mem);
  cmark_node *cur;
  cmark_event_type ev_type;
  char *result;
  cmark_iter *iter = cmark_iter_new(root);

  cmark_renderer renderer = {options,
                             mem,    &buf,    &pref,      0,      width,
                             0,      0,       true,       true,   false,
                             false,  NULL,
                             outc,   S_cr,    S_blankline, S_out};

  while ((ev_type = cmark_iter_next(iter)) != CMARK_EVENT_DONE) {
    cur = cmark_iter_get_node(iter);
    if (!render_node(&renderer, cur, ev_type, options)) {
      // a false value causes us to skip processing
      // the node's contents.  this is used for
      // autolinks.
      cmark_iter_reset(iter, cur, CMARK_EVENT_EXIT);
    }
  }

  // ensure final newline
  if (renderer.buffer->size == 0 || renderer.buffer->ptr[renderer.buffer->size - 1] != '\n') {
    cmark_strbuf_putc(renderer.buffer, '\n');
  }

  result = (char *)cmark_strbuf_detach(renderer.buffer);

  cmark_iter_free(iter);
  cmark_strbuf_free(renderer.prefix);
  cmark_strbuf_free(renderer.buffer);

  return result;
}
