/*!The Treasure Box Library
 * 
 * TBox is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * TBox is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with TBox; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
 *
 * @author      ruki
 * @file        http.h
 * @ingroup     network
 *
 */
#ifndef TB_NETWORK_HTTP_H
#define TB_NETWORK_HTTP_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "cookies.h"
#include "url.h"
#include "../string/string.h"
#include "../container/container.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/// the http option code: get
#define TB_HTTP_OPTION_CODE_GET(x)          ((x) + 1)

/// the http option code: set
#define TB_HTTP_OPTION_CODE_SET(x)          (0xff00 | ((x) + 1))

/// the http option code is setter?
#define TB_HTTP_OPTION_CODE_IS_SET(x)       ((x) & 0xff00)

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the http method enum
typedef enum __tb_http_method_e
{
    TB_HTTP_METHOD_GET                          = 0
,   TB_HTTP_METHOD_POST                         = 1
,   TB_HTTP_METHOD_HEAD                         = 2
,   TB_HTTP_METHOD_PUT                          = 3
,   TB_HTTP_METHOD_OPTIONS                      = 4
,   TB_HTTP_METHOD_DELETE                       = 5
,   TB_HTTP_METHOD_TRACE                        = 6
,   TB_HTTP_METHOD_CONNECT                      = 7

}tb_http_method_e;

/// the http code enum
typedef enum __tb_http_code_e
{
    TB_HTTP_CODE_CONTINUE                       = 100
,   TB_HTTP_CODE_SWITCHING_PROTOCOLS            = 101
,   TB_HTTP_CODE_PROCESSING                     = 102

,   TB_HTTP_CODE_OK                             = 200
,   TB_HTTP_CODE_CREATED                        = 201
,   TB_HTTP_CODE_ACCEPTED                       = 202
,   TB_HTTP_CODE_NON_AUTHORITATIVE_INFORMATION  = 203
,   TB_HTTP_CODE_NO_CONTENT                     = 204
,   TB_HTTP_CODE_RESET_CONTENT                  = 205
,   TB_HTTP_CODE_PARTIAL_CONTENT                = 206
,   TB_HTTP_CODE_MULTI_STATUS                   = 207

,   TB_HTTP_CODE_MULTIPLE_CHOICES               = 300
,   TB_HTTP_CODE_MOVED_PERMANENTLY              = 301
,   TB_HTTP_CODE_MOVED_TEMPORARILY              = 302
,   TB_HTTP_CODE_SEE_OTHER                      = 303
,   TB_HTTP_CODE_NOT_MODIFIED                   = 304
,   TB_HTTP_CODE_USE_PROXY                      = 305
,   TB_HTTP_CODE_SWITCH_PROXY                   = 306
,   TB_HTTP_CODE_TEMPORARY_REDIRECT             = 307

,   TB_HTTP_CODE_BAD_REQUEST                    = 400
,   TB_HTTP_CODE_UNAUTHORIZED                   = 401
,   TB_HTTP_CODE_FORBIDDEN                      = 403
,   TB_HTTP_CODE_NOT_FOUND                      = 404
,   TB_HTTP_CODE_METHOD_NOT_ALLOWED             = 405
,   TB_HTTP_CODE_NOT_ACCEPTABLE                 = 406
,   TB_HTTP_CODE_REQUEST_TIMEOUT                = 408
,   TB_HTTP_CODE_CONFLICT                       = 409
,   TB_HTTP_CODE_GONE                           = 410
,   TB_HTTP_CODE_LENGTH_REQUIRED                = 411
,   TB_HTTP_CODE_PRECONDITION_FAILED            = 412
,   TB_HTTP_CODE_REQUEST_ENTITY_TOO_LONG        = 413
,   TB_HTTP_CODE_REQUEST_URI_TOO_LONG           = 414
,   TB_HTTP_CODE_UNSUPPORTED_MEDIA_TYPE         = 415
,   TB_HTTP_CODE_RANGE_NOT_SATISFIABLE          = 416
,   TB_HTTP_CODE_EXPECTATION_FAILED             = 417
,   TB_HTTP_CODE_UNPROCESSABLE_ENTITY           = 422
,   TB_HTTP_CODE_LOCKED                         = 423
,   TB_HTTP_CODE_FAILED_DEPENDENCY              = 424
,   TB_HTTP_CODE_UNORDERED_COLLECTION           = 425
,   TB_HTTP_CODE_UPGRADE_REQUIRED               = 426
,   TB_HTTP_CODE_RETRY_WITH                     = 449

,   TB_HTTP_CODE_INTERNAL_SERVER_ERROR          = 500
,   TB_HTTP_CODE_NOT_IMPLEMENTED                = 501
,   TB_HTTP_CODE_BAD_GATEWAY                    = 502
,   TB_HTTP_CODE_SERVICE_UNAVAILABLE            = 503
,   TB_HTTP_CODE_GATEWAY_TIMEOUT                = 504
,   TB_HTTP_CODE_INSUFFICIENT_STORAGE           = 507
,   TB_HTTP_CODE_LOOP_DETECTED                  = 508
,   TB_HTTP_CODE_NOT_EXTENDED                   = 510

}tb_http_code_e;

/// the http option enum
typedef enum __tb_http_option_e
{
    TB_HTTP_OPTION_NONE                 = 0

,   TB_HTTP_OPTION_GET_SSL              = TB_HTTP_OPTION_CODE_GET(1)
,   TB_HTTP_OPTION_GET_URL              = TB_HTTP_OPTION_CODE_GET(2)
,   TB_HTTP_OPTION_GET_HOST             = TB_HTTP_OPTION_CODE_GET(3)
,   TB_HTTP_OPTION_GET_PORT             = TB_HTTP_OPTION_CODE_GET(4)
,   TB_HTTP_OPTION_GET_PATH             = TB_HTTP_OPTION_CODE_GET(5)
,   TB_HTTP_OPTION_GET_HEAD             = TB_HTTP_OPTION_CODE_GET(6)
,   TB_HTTP_OPTION_GET_RANGE            = TB_HTTP_OPTION_CODE_GET(7)
,   TB_HTTP_OPTION_GET_METHOD           = TB_HTTP_OPTION_CODE_GET(8)
,   TB_HTTP_OPTION_GET_VERSION          = TB_HTTP_OPTION_CODE_GET(9) 
,   TB_HTTP_OPTION_GET_TIMEOUT          = TB_HTTP_OPTION_CODE_GET(10)
,   TB_HTTP_OPTION_GET_COOKIES          = TB_HTTP_OPTION_CODE_GET(11)
,   TB_HTTP_OPTION_GET_REDIRECT         = TB_HTTP_OPTION_CODE_GET(12) 
,   TB_HTTP_OPTION_GET_HEAD_FUNC        = TB_HTTP_OPTION_CODE_GET(13)
,   TB_HTTP_OPTION_GET_HEAD_PRIV        = TB_HTTP_OPTION_CODE_GET(14)
,   TB_HTTP_OPTION_GET_AUTO_UNZIP       = TB_HTTP_OPTION_CODE_GET(15)
,   TB_HTTP_OPTION_GET_POST_URL         = TB_HTTP_OPTION_CODE_GET(16)
,   TB_HTTP_OPTION_GET_POST_DATA        = TB_HTTP_OPTION_CODE_GET(17)
,   TB_HTTP_OPTION_GET_POST_FUNC        = TB_HTTP_OPTION_CODE_GET(18)
,   TB_HTTP_OPTION_GET_POST_PRIV        = TB_HTTP_OPTION_CODE_GET(19)
,   TB_HTTP_OPTION_GET_POST_LRATE       = TB_HTTP_OPTION_CODE_GET(20)

,   TB_HTTP_OPTION_SET_SSL              = TB_HTTP_OPTION_CODE_SET(1)
,   TB_HTTP_OPTION_SET_URL              = TB_HTTP_OPTION_CODE_SET(2)
,   TB_HTTP_OPTION_SET_HOST             = TB_HTTP_OPTION_CODE_SET(3)
,   TB_HTTP_OPTION_SET_PORT             = TB_HTTP_OPTION_CODE_SET(4)
,   TB_HTTP_OPTION_SET_PATH             = TB_HTTP_OPTION_CODE_SET(5)
,   TB_HTTP_OPTION_SET_HEAD             = TB_HTTP_OPTION_CODE_SET(6)
,   TB_HTTP_OPTION_SET_RANGE            = TB_HTTP_OPTION_CODE_SET(7)
,   TB_HTTP_OPTION_SET_METHOD           = TB_HTTP_OPTION_CODE_SET(8)
,   TB_HTTP_OPTION_SET_VERSION          = TB_HTTP_OPTION_CODE_SET(9)
,   TB_HTTP_OPTION_SET_TIMEOUT          = TB_HTTP_OPTION_CODE_SET(10)
,   TB_HTTP_OPTION_SET_COOKIES          = TB_HTTP_OPTION_CODE_SET(11)
,   TB_HTTP_OPTION_SET_REDIRECT         = TB_HTTP_OPTION_CODE_SET(12)
,   TB_HTTP_OPTION_SET_HEAD_FUNC        = TB_HTTP_OPTION_CODE_SET(13)
,   TB_HTTP_OPTION_SET_HEAD_PRIV        = TB_HTTP_OPTION_CODE_SET(14)
,   TB_HTTP_OPTION_SET_AUTO_UNZIP       = TB_HTTP_OPTION_CODE_SET(15)
,   TB_HTTP_OPTION_SET_POST_URL         = TB_HTTP_OPTION_CODE_SET(16)
,   TB_HTTP_OPTION_SET_POST_DATA        = TB_HTTP_OPTION_CODE_SET(17)
,   TB_HTTP_OPTION_SET_POST_FUNC        = TB_HTTP_OPTION_CODE_SET(18)
,   TB_HTTP_OPTION_SET_POST_PRIV        = TB_HTTP_OPTION_CODE_SET(19)
,   TB_HTTP_OPTION_SET_POST_LRATE       = TB_HTTP_OPTION_CODE_SET(20)

}tb_http_option_e;

/// the http range type
typedef struct __tb_http_range_t
{
    /// the begin offset
    tb_hize_t           bof;

    /// the end offset
    tb_hize_t           eof;

}tb_http_range_t;

/// the http ref type
typedef struct{}*       tb_http_ref_t;

/*! the http head func type
 *
 * @param line          the http head line
 * @param priv          the func private data
 *
 * @return              tb_true: ok and continue it if need, tb_false: break it
 */
typedef tb_bool_t       (*tb_http_head_func_t)(tb_char_t const* line, tb_cpointer_t priv);

/*! the http post func type
 *
 * @param offset        the istream offset
 * @param size          the istream size, no size: -1
 * @param save          the saved size
 * @param rate          the current rate, bytes/s
 * @param priv          the func private data
 *
 * @return              tb_true: ok and continue it if need, tb_false: break it
 */
typedef tb_bool_t       (*tb_http_post_func_t)(tb_size_t state, tb_hize_t offset, tb_hong_t size, tb_hize_t save, tb_size_t rate, tb_cpointer_t priv);

/// the http option type
typedef struct __tb_http_option_t
{
    /// the method
    tb_uint16_t         method      : 4;

    /// auto unzip for gzip encoding?
    tb_uint16_t         bunzip      : 1;

    /// the http version, 0: HTTP/1.0, 1: HTTP/1.1
    tb_uint16_t         version     : 1;

    /// the redirect maxn
    tb_uint16_t         redirect    : 10;

    /// the url
    tb_url_t            url;

    /// timeout: ms
    tb_long_t           timeout;

    /// range
    tb_http_range_t     range;

    /// the cookies
    tb_cookies_ref_t    cookies;

    /// the priv data
    tb_pointer_t        head_priv;

    /// the head func
    tb_http_head_func_t head_func;

    /// the head data
    tb_buffer_t         head_data;

    /// the post url
    tb_url_t            post_url;

    /// the post data
    tb_byte_t const*    post_data;

    /// the post size
    tb_size_t           post_size;

    /// the post func
    tb_http_post_func_t post_func;

    /// the post data
    tb_cpointer_t       post_priv;

    /// the post limit rate
    tb_size_t           post_lrate;

}tb_http_option_t;

/// the http status type
typedef struct __tb_http_status_t
{
    /// the http code
    tb_uint16_t         code        : 10;

    /// the http version
    tb_uint16_t         version     : 1;

    /// keep alive?
    tb_uint16_t         balived     : 1;

    /// be able to seek?
    tb_uint16_t         bseeked     : 1;

    /// is chunked?
    tb_uint16_t         bchunked    : 1;

    /// is gzip?
    tb_uint16_t         bgzip       : 1;

    /// is deflate?
    tb_uint16_t         bdeflate    : 1;

    /// the state
    tb_size_t           state;

    /// the document size
    tb_hong_t           document_size;

    /// the current content size, maybe in range
    tb_hong_t           content_size;

    /// the content type
    tb_string_t         content_type;

    /// the location
    tb_string_t         location;

}tb_http_status_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init http
 *
 * return               the http 
 */
tb_http_ref_t           tb_http_init(tb_noarg_t);

/*! exit http
 *
 * @param http          the http 
 */
tb_void_t               tb_http_exit(tb_http_ref_t http);

/*! kill http
 *
 * @param http          the http 
 */
tb_void_t               tb_http_kill(tb_http_ref_t http);

/*! wait the http 
 *
 * blocking wait the single event object, so need not aiop 
 * return the event type if ok, otherwise return 0 for timeout
 *
 * @param http          the http 
 * @param aioe          the aioe
 * @param timeout       the timeout value, return immediately if 0, infinity if -1
 *
 * @return              the event type, return 0 if timeout, return -1 if error
 */
tb_long_t               tb_http_wait(tb_http_ref_t http, tb_size_t aioe, tb_long_t timeout);

/*! open the http
 *
 * @param http          the http 
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_http_open(tb_http_ref_t http);

/*! close http
 *
 * @param http          the http 
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_http_clos(tb_http_ref_t http);

/*! seek http
 *
 * @param http          the http 
 * @param offset        the offset
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_http_seek(tb_http_ref_t http, tb_hize_t offset);

/*! read data, non-blocking
 *
 * @param http          the http 
 * @param data          the data
 * @param size          the size
 *
 * @return              ok: real size, continue: 0, fail: -1
 */
tb_long_t               tb_http_read(tb_http_ref_t http, tb_byte_t* data, tb_size_t size);

/*! read data, blocking
 *
 * @param http          the http 
 * @param data          the data
 * @param size          the size
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_http_bread(tb_http_ref_t http, tb_byte_t* data, tb_size_t size);

/*! ctrl the http option
 *
 * @param http          the http 
 * @param option        the ctrl option
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_http_ctrl(tb_http_ref_t http, tb_size_t option, ...);

/*! the http status
 *
 * @param http          the http 
 *
 * @return              the http status
 */
tb_http_status_t const* tb_http_status(tb_http_ref_t http);


/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

