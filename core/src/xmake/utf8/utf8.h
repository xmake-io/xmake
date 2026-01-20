#ifndef XM_UTF8_UTF8_H
#define XM_UTF8_UTF8_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#define xm_utf8_iscont(c)    (((c) & 0xC0) == 0x80)
#define xm_utf8_iscontp(p)   xm_utf8_iscont(*(p))

#define XM_UTF8_MAXUNICODE  0x10FFFFu
#define XM_UTF8_MAXUTF      0x7FFFFFFFu
#define XM_UTF8_MSGInvalid  "invalid UTF-8 code"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */
typedef tb_uint32_t xm_utf8_int_t;
typedef tb_bool_t (*xm_utf8_codepoint_func_t)(xm_utf8_int_t code, tb_cpointer_t udata);

/* //////////////////////////////////////////////////////////////////////////////////////
 * inline interfaces
 */
static __tb_inline__ tb_long_t xm_utf8_posrelat(tb_long_t pos, tb_size_t len) {
    if (pos >= 0) {
        return pos;
    } else if (0u - (tb_size_t)pos > len) {
        return 0;
    } else {
        return (tb_long_t)len + pos + 1;
    }
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

tb_char_t const*    xm_utf8_decode(tb_char_t const* s, xm_utf8_int_t* val, tb_bool_t strict);
tb_size_t           xm_utf8_encode(tb_char_t* s, xm_utf8_int_t val);

tb_long_t           xm_utf8_len_impl(tb_char_t const* s, tb_size_t len, tb_long_t posi, tb_long_t posj, tb_bool_t strict, tb_size_t* errpos);
tb_long_t           xm_utf8_offset_impl(tb_char_t const* s, tb_size_t len, tb_long_t n, tb_long_t posi);
tb_bool_t           xm_utf8_codepoint_impl(tb_char_t const* s, tb_size_t len, tb_long_t posi, tb_long_t posj, tb_bool_t strict, xm_utf8_codepoint_func_t func, tb_cpointer_t udata);
tb_long_t           xm_utf8_find_impl(tb_char_t const* s, tb_size_t len, tb_char_t const* sub, tb_size_t sublen, tb_long_t init, tb_long_t* pchar_end);
tb_char_t const*    xm_utf8_sub_impl(tb_char_t const* s, tb_size_t len, tb_long_t i, tb_long_t j, tb_size_t* psublen);

#endif
