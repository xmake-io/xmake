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
 * @file        stream.h
 * @ingroup     stream
 *
 */
#ifndef TB_STREAM_H
#define TB_STREAM_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "async_stream.h"
#include "static_stream.h"
#include "transfer.h"
#include "transfer_pool.h"
#include "filter.h"

/*!architecture
 *
 *
 * <pre>   
 *                             wait - loop
 *                              | 
 *                              |                                          - data
 *                            [aioo]                                       |
 *                      ----- stream -------- stream ----------------------- file
 *                      |                        |                         |
 *                      |                        |                         - sock 
 *                      |                        |                         |
 *                      |                        |                         - http
 *                      |                        |           - charset
 *                      |                        |          |
 *                      |                        - filter - |- chunked 
 *  transfer ---------  |                                   |        
 *                      |                                   |- cache
 *                      |                                   |
 *                      |                                    - zip
 *                      |
 *                      ----- stream                
 *                                                            
 *                                                                        - loop
 *                                                                 [asio] |
 *                                                                  aicp -| loop
 *                                                                   |    |
 *                                                                   |    - ...                                  - data
 *                                                                 [aico]                                        |
 *                                            -------------------- async_stream -------- async_stream ------------ file
 *                                            |                                       |                          |
 *                                            |                                       |                          - sock
 *                            ----------------                                        |                          |
 *                            |                                                       |                          - http
 *                 -----  transfer                                                    |           - charset
 *                |           |                                                       |          |
 *                |           ----------------                                        - filter - |- chunked 
 *                |                           |                                            |     |        
 *  transfer_pool  -----  transfer            |                                            |     |- cache
 *                |                           |                                            |     |
 *                |                           |                                            |      - zip    
 *                |                           |                                            |
 *                 -----   ...                |                                            |
 *                                            |                                         static_stream - [data, size]
 *                                            |                                     
 *                                            -------------------- async_stream
 * url: 
 * data://base64
 * file://path or unix path: e.g. /root/xxxx/file
 * sock://host:port?tcp=
 * sock://host:port?udp=
 * socks://host:port
 * http://host:port/path?arg0=&arg1=...
 * https://host:port/path?arg0=&arg1=...
 * </pre>
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the stream block maxn
#define TB_STREAM_BLOCK_MAXN                  (8192)

// the stream bitops
#ifdef TB_WORDS_BIGENDIAN
#   define tb_stream_bread_u16_ne(stream)         tb_stream_bread_u16_be(stream)
#   define tb_stream_bread_s16_ne(stream)         tb_stream_bread_s16_be(stream)
#   define tb_stream_bread_u24_ne(stream)         tb_stream_bread_u24_be(stream)
#   define tb_stream_bread_s24_ne(stream)         tb_stream_bread_s24_be(stream)
#   define tb_stream_bread_u32_ne(stream)         tb_stream_bread_u32_be(stream)
#   define tb_stream_bread_s32_ne(stream)         tb_stream_bread_s32_be(stream)
#   define tb_stream_bread_u64_ne(stream)         tb_stream_bread_u64_be(stream)
#   define tb_stream_bread_s64_ne(stream)         tb_stream_bread_s64_be(stream)

#   define tb_stream_bwrit_u16_ne(stream, val)    tb_stream_bwrit_u16_be(stream, val)
#   define tb_stream_bwrit_s16_ne(stream, val)    tb_stream_bwrit_s16_be(stream, val)
#   define tb_stream_bwrit_u24_ne(stream, val)    tb_stream_bwrit_u24_be(stream, val)
#   define tb_stream_bwrit_s24_ne(stream, val)    tb_stream_bwrit_s24_be(stream, val)
#   define tb_stream_bwrit_u32_ne(stream, val)    tb_stream_bwrit_u32_be(stream, val)
#   define tb_stream_bwrit_s32_ne(stream, val)    tb_stream_bwrit_s32_be(stream, val)
#   define tb_stream_bwrit_u64_ne(stream, val)    tb_stream_bwrit_u64_be(stream, val)
#   define tb_stream_bwrit_s64_ne(stream, val)    tb_stream_bwrit_s64_be(stream, val)

#else
#   define tb_stream_bread_u16_ne(stream)         tb_stream_bread_u16_le(stream)
#   define tb_stream_bread_s16_ne(stream)         tb_stream_bread_s16_le(stream)
#   define tb_stream_bread_u24_ne(stream)         tb_stream_bread_u24_le(stream)
#   define tb_stream_bread_s24_ne(stream)         tb_stream_bread_s24_le(stream)
#   define tb_stream_bread_u32_ne(stream)         tb_stream_bread_u32_le(stream)
#   define tb_stream_bread_s32_ne(stream)         tb_stream_bread_s32_le(stream)
#   define tb_stream_bread_u64_ne(stream)         tb_stream_bread_u64_le(stream)
#   define tb_stream_bread_s64_ne(stream)         tb_stream_bread_s64_le(stream)

#   define tb_stream_bwrit_u16_ne(stream, val)    tb_stream_bwrit_u16_le(stream, val)
#   define tb_stream_bwrit_s16_ne(stream, val)    tb_stream_bwrit_s16_le(stream, val)
#   define tb_stream_bwrit_u24_ne(stream, val)    tb_stream_bwrit_u24_le(stream, val)
#   define tb_stream_bwrit_s24_ne(stream, val)    tb_stream_bwrit_s24_le(stream, val)
#   define tb_stream_bwrit_u32_ne(stream, val)    tb_stream_bwrit_u32_le(stream, val)
#   define tb_stream_bwrit_s32_ne(stream, val)    tb_stream_bwrit_s32_le(stream, val)
#   define tb_stream_bwrit_u64_ne(stream, val)    tb_stream_bwrit_u64_le(stream, val)
#   define tb_stream_bwrit_s64_ne(stream, val)    tb_stream_bwrit_s64_le(stream, val)

#endif

#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
#   ifdef TB_FLOAT_BIGENDIAN
#       define tb_stream_bread_double_nbe(stream)         tb_stream_bread_double_bbe(stream)
#       define tb_stream_bread_double_nle(stream)         tb_stream_bread_double_ble(stream)

#       define tb_stream_bwrit_double_nbe(stream, val)    tb_stream_bwrit_double_bbe(stream, val)
#       define tb_stream_bwrit_double_nle(stream, val)    tb_stream_bwrit_double_ble(stream, val)
#   else
#       define tb_stream_bread_double_nbe(stream)         tb_stream_bread_double_lbe(stream)
#       define tb_stream_bread_double_nle(stream)         tb_stream_bread_double_lle(stream)

#       define tb_stream_bwrit_double_nbe(stream, val)    tb_stream_bwrit_double_lbe(stream, val)
#       define tb_stream_bwrit_double_nle(stream, val)    tb_stream_bwrit_double_lle(stream, val)
#   endif
#   ifdef TB_WORDS_BIGENDIAN
#       define tb_stream_bread_float_ne(stream)           tb_stream_bread_float_be(stream)
#       define tb_stream_bwrit_float_ne(stream, val)      tb_stream_bwrit_float_be(stream, val)

#       define tb_stream_bread_double_nne(stream)         tb_stream_bread_double_nbe(stream)
#       define tb_stream_bread_double_bne(stream)         tb_stream_bread_double_bbe(stream)
#       define tb_stream_bread_double_lne(stream)         tb_stream_bread_double_lbe(stream)

#       define tb_stream_bwrit_double_nne(stream, val)    tb_stream_bwrit_double_nbe(stream, val)
#       define tb_stream_bwrit_double_bne(stream, val)    tb_stream_bwrit_double_bbe(stream, val)
#       define tb_stream_bwrit_double_lne(stream, val)    tb_stream_bwrit_double_lbe(stream, val)
#   else
#       define tb_stream_bread_float_ne(stream)           tb_stream_bread_float_le(stream)
#       define tb_stream_bwrit_float_ne(stream, val)      tb_stream_bwrit_float_le(stream, val)

#       define tb_stream_bread_double_nne(stream)         tb_stream_bread_double_nle(stream)
#       define tb_stream_bread_double_bne(stream)         tb_stream_bread_double_ble(stream)
#       define tb_stream_bread_double_lne(stream)         tb_stream_bread_double_lle(stream)

#       define tb_stream_bwrit_double_nne(stream, val)    tb_stream_bwrit_double_nle(stream, val)
#       define tb_stream_bwrit_double_bne(stream, val)    tb_stream_bwrit_double_ble(stream, val)
#       define tb_stream_bwrit_double_lne(stream, val)    tb_stream_bwrit_double_lle(stream, val)
#   endif
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init stream 
 *
 * @param type          the stream type
 * @param type_size     the stream type size
 * @param cache         the cache size
 * @param open          the stream impl func: open
 * @param clos          the stream impl func: clos
 * @param exit          the stream impl func: exit, optional
 * @param ctrl          the stream impl func: ctrl
 * @param wait          the stream impl func: wait
 * @param read          the stream impl func: read
 * @param writ          the stream impl func: writ
 * @param seek          the stream impl func: seek, optional
 * @param sync          the stream impl func: sync, optional
 * @param kill          the stream impl func: kill, optional
 *
 * @return              the stream
 * 
 * @code
    // the custom xxxx stream type
    typedef struct __tb_stream_xxxx_impl_t
    {
        // the xxxx data
        tb_handle_t         xxxx;

    }tb_stream_xxxx_impl_t;

    static tb_bool_t tb_stream_xxxx_impl_open(tb_stream_ref_t stream)
    {
        // check
        tb_stream_xxxx_impl_t* impl = (tb_stream_xxxx_impl_t*)stream;
        tb_assert_and_check_return_val(impl, tb_false);

        // ok
        return tb_true;
    }
    static tb_bool_t tb_stream_xxxx_impl_clos(tb_stream_ref_t stream)
    {
        // check
        tb_stream_xxxx_impl_t* impl = (tb_stream_xxxx_impl_t*)stream;
        tb_assert_and_check_return_val(impl, tb_false);

        // ok
        return tb_true;
    }

    // define other xxxx stream func
    // ...

    // init stream
    tb_stream_ref_t stream = tb_stream_init(    TB_STREAM_TYPE_XXXX
                                            ,   sizeof(tb_stream_xxxx_impl_t)
                                            ,   0
                                            ,   tb_stream_xxxx_impl_open
                                            ,   tb_stream_xxxx_impl_clos
                                            ,   tb_stream_xxxx_impl_exit
                                            ,   tb_stream_xxxx_impl_ctrl
                                            ,   tb_stream_xxxx_impl_wait
                                            ,   tb_stream_xxxx_impl_read
                                            ,   tb_stream_xxxx_impl_writ
                                            ,   tb_stream_xxxx_impl_seek
                                            ,   tb_stream_xxxx_impl_sync
                                            ,   tb_stream_xxxx_impl_kill);

    // using stream
    // ...

 * @endcode
 */
tb_stream_ref_t         tb_stream_init(     tb_size_t type
                                        ,   tb_size_t type_size
                                        ,   tb_size_t cache
                                        ,   tb_bool_t (*open)(tb_stream_ref_t stream)
                                        ,   tb_bool_t (*clos)(tb_stream_ref_t stream)
                                        ,   tb_void_t (*exit)(tb_stream_ref_t stream)
                                        ,   tb_bool_t (*ctrl)(tb_stream_ref_t stream, tb_size_t ctrl, tb_va_list_t args)
                                        ,   tb_long_t (*wait)(tb_stream_ref_t stream, tb_size_t wait, tb_long_t timeout)
                                        ,   tb_long_t (*read)(tb_stream_ref_t stream, tb_byte_t* data, tb_size_t size)
                                        ,   tb_long_t (*writ)(tb_stream_ref_t stream, tb_byte_t const* data, tb_size_t size)
                                        ,   tb_bool_t (*seek)(tb_stream_ref_t stream, tb_hize_t offset)
                                        ,   tb_bool_t (*sync)(tb_stream_ref_t stream, tb_bool_t bclosing)
                                        ,   tb_void_t (*kill)(tb_stream_ref_t stream));

/*! init data stream 
 *
 * @return              the stream
 */
tb_stream_ref_t         tb_stream_init_data(tb_noarg_t);

/*! init file stream 
 *
 * @return              the stream
 */
tb_stream_ref_t         tb_stream_init_file(tb_noarg_t);

/*! init sock stream 
 *
 * @return              the stream
 */
tb_stream_ref_t         tb_stream_init_sock(tb_noarg_t);

/*! init http stream 
 *
 * @return              the stream
 */
tb_stream_ref_t         tb_stream_init_http(tb_noarg_t);

/*! init filter stream 
 *
 * @return              the stream
 */
tb_stream_ref_t         tb_stream_init_filter(tb_noarg_t);

/*! exit stream
 *
 * @param stream        the stream
 */
tb_void_t               tb_stream_exit(tb_stream_ref_t stream);

/*! init stream from url
 *
 * @code
 *
    // init stream
    tb_stream_ref_t stream = tb_stream_init_from_url("http://www.xxx.com/file");
    if (stream)
    {
        // open stream
        if (tb_stream_open(stream))
        {
            // ...
        }

        // exit stream
        tb_stream_exit(stream);
    }
 *
 * @endcode
 *
 * @param url           the url
 *                      - data://base64
 *                      - file://path or unix path: e.g. /root/xxxx/file
 *                      - sock://host:port?tcp=
 *                      - sock://host:port?udp=
 *                      - socks://host:port
 *                      - http://host:port/path?arg0=&arg1=...
 *                      - https://host:port/path?arg0=&arg1=...
 *
 * @return              the stream
 */
tb_stream_ref_t         tb_stream_init_from_url(tb_char_t const* url);

/*! init stream from data
 *
 * @param data          the data
 * @param size          the size
 *
 * @return              the stream
 */
tb_stream_ref_t         tb_stream_init_from_data(tb_byte_t const* data, tb_size_t size);

/*! init stream from file
 *
 * @param path          the file path
 * @param mode          the file mode, using the default ro mode if zero
 *
 * @return              the stream
 */
tb_stream_ref_t         tb_stream_init_from_file(tb_char_t const* path, tb_size_t mode);

/*! init stream from sock
 *
 * @param host          the host
 * @param port          the port
 * @param type          the socket type, tcp or udp
 * @param bssl          enable ssl?
 *
 * @return              the stream
 */
tb_stream_ref_t         tb_stream_init_from_sock(tb_char_t const* host, tb_uint16_t port, tb_size_t type, tb_bool_t bssl);

/*! init stream from http or https
 *
 * @param host          the host
 * @param port          the port
 * @param path          the path
 * @param bssl          enable ssl?
 *
 * @return              the stream
 */
tb_stream_ref_t         tb_stream_init_from_http(tb_char_t const* host, tb_uint16_t port, tb_char_t const* path, tb_bool_t bssl);

/*! init filter stream from null
 *
 * @param stream        the stream
 *
 * @return              the stream
 */
tb_stream_ref_t         tb_stream_init_filter_from_null(tb_stream_ref_t stream);

/*! init filter stream from zip
 *
 * @param stream        the stream
 * @param algo          the zip algorithm
 * @param action        the zip action
 *
 * @return              the stream
 */
tb_stream_ref_t         tb_stream_init_filter_from_zip(tb_stream_ref_t stream, tb_size_t algo, tb_size_t action);

/*! init filter stream from cache
 *
 * @param stream        the stream
 * @param size          the initial cache size, using the default size if be zero
 *
 * @return              the stream
 */
tb_stream_ref_t         tb_stream_init_filter_from_cache(tb_stream_ref_t stream, tb_size_t size);

/*! init filter stream from charset
 *
 * @param stream        the stream
 * @param fr            the from charset
 * @param to            the to charset
 *
 * @return              the stream
 */
tb_stream_ref_t         tb_stream_init_filter_from_charset(tb_stream_ref_t stream, tb_size_t fr, tb_size_t to);

/*! init filter stream from chunked
 *
 * @param stream        the stream
 * @param dechunked     decode the chunked data?
 *
 * @return              the stream
 */
tb_stream_ref_t         tb_stream_init_filter_from_chunked(tb_stream_ref_t stream, tb_bool_t dechunked);

/*! wait stream 
 *
 * blocking wait the single event object, so need not aiop 
 * return the event type if ok, otherwise return 0 for timeout
 *
 * @param stream        the stream 
 * @param wait          the wait type
 * @param timeout       the timeout value, return immediately if 0, infinity if -1
 *
 * @return              the event type, return 0 if timeout, return -1 if error
 */
tb_long_t               tb_stream_wait(tb_stream_ref_t stream, tb_size_t wait, tb_long_t timeout);

/*! the state
 *
 * @param stream        the stream
 *
 * @return              the state
 */
tb_size_t               tb_stream_state(tb_stream_ref_t stream);

/*! set the state
 *
 * @param stream        the stream
 * @param state         the state
 */
tb_void_t               tb_stream_state_set(tb_stream_ref_t stream, tb_size_t state);

/*! the stream type
 *
 * @param stream        the stream
 *
 * @return              the stream type
 */
tb_size_t               tb_stream_type(tb_stream_ref_t stream);

/*! the stream size and not seeking it
 *
 * @param stream        the stream
 *
 * @return              the stream size, no size: -1, empty or error: 0
 */
tb_hong_t               tb_stream_size(tb_stream_ref_t stream);

/*! the stream left size and not seeking it 
 *
 * @param stream        the stream
 *
 * @return              the stream left size, no size: infinity, empty or end: 0
 */
tb_hize_t               tb_stream_left(tb_stream_ref_t stream);

/*! the stream is end?
 *
 * @param stream        the stream
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_beof(tb_stream_ref_t stream);

/*! the stream offset
 *
 * the offset is read + writ and using seek for modifying it if size != -1, .e.g: data, file, .. 
 * the offset is calculated from the last read/writ and not seeking it if size == -1, .e.g: sock, filter, ..
 *
 * @param stream        the stream
 *
 * @return              the stream offset
 */
tb_hize_t               tb_stream_offset(tb_stream_ref_t stream);

/*! is opened?
 *
 * @param stream        the stream
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_is_opened(tb_stream_ref_t stream);

/*! is closed?
 *
 * @param stream        the stream
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_is_closed(tb_stream_ref_t stream);

/*! is killed?
 *
 * @param stream        the stream
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_is_killed(tb_stream_ref_t stream);

/*! the stream url
 *
 * @param stream        the stream
 *
 * @return              the stream url
 */
tb_url_ref_t            tb_stream_url(tb_stream_ref_t stream);

/*! the stream timeout
 *
 * @param stream        the stream
 *
 * @return              the stream timeout
 */
tb_long_t               tb_stream_timeout(tb_stream_ref_t stream);

/*! ctrl stream
 *
 * @param stream        the stream
 * @param ctrl          the ctrl code
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_ctrl(tb_stream_ref_t stream, tb_size_t ctrl, ...);

/*! ctrl stream with arguments
 *
 * @param stream        the stream
 * @param ctrl          the ctrl code
 * @param args          the ctrl args
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_ctrl_with_args(tb_stream_ref_t stream, tb_size_t ctrl, tb_va_list_t args);

/*! kill stream
 *
 * @param stream        the stream
 */
tb_void_t               tb_stream_kill(tb_stream_ref_t stream);

/*! open stream
 *
 * @param stream        the stream
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_open(tb_stream_ref_t stream);

/*! close stream
 *
 * @param stream        the stream
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_clos(tb_stream_ref_t stream);

/*! read data, non-blocking
 * 
 * @code

    tb_long_t read = 0;
    tb_byte_t data[TB_STREAM_BLOCK_MAXN];
    while (!tb_stream_beof(stream))
    {
        // read data
        tb_long_t real = tb_stream_read(stream, data, sizeof(data));    

        // ok?
        if (real > 0) read += real;
        // no data? continue it
        else if (!real)
        {
            // wait
            real = tb_stream_wait(stream, TB_STREAM_WAIT_READ, tb_stream_timeout(stream));
            tb_check_break(real > 0);

            // has read?
            tb_assert_and_check_break(real & TB_STREAM_WAIT_READ);
        }
        // failed or end?
        else break;
    }

 * @endcode
 *
 * @param stream        the stream
 * @param data          the data
 * @param size          the size
 *
 * @return              the real size or -1
 */
tb_long_t               tb_stream_read(tb_stream_ref_t stream, tb_byte_t* data, tb_size_t size);

/*! writ data, non-blocking
 *
 * @param stream        the stream
 * @param data          the data
 * @param size          the size
 *
 * @return              the real size or -1
 */
tb_long_t               tb_stream_writ(tb_stream_ref_t stream, tb_byte_t const* data, tb_size_t size);

/*! block read
 * 
 * @code
 *
    // get stream size
    //
    // @note 
    // size may be < -1 for the http(chunked)/filter/.. stream
    // we need call tb_stream_read for reading data if size < 0
    //
    tb_hong_t size = tb_stream_size(stream);
    tb_assert(size > 0);

    // make data
    tb_byte_t* data = tb_malloc((tb_size_t)size);
    if (data)
    {
        // read data
        tb_bool_t ok = tb_stream_bread(stream, data, size);

        // exit data
        tb_free(data)
    }
 *
 * @endcode
 *
 * @param stream        the stream
 * @param data          the data
 * @param size          the size
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bread(tb_stream_ref_t stream, tb_byte_t* data, tb_size_t size);

/*! block writ
 *
 * @param stream        the stream
 * @param data          the data
 * @param size          the size
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit(tb_stream_ref_t stream, tb_byte_t const* data, tb_size_t size);

/*! sync stream
 *
 * @param stream        the stream
 * @param bclosing      is closing?
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_sync(tb_stream_ref_t stream, tb_bool_t bclosing);

/*! need stream
 *
 * @code
 
    // need 16-bytes data
    tb_byte_t* data = tb_null;
    if (tb_stream_need(stream, &data, 16))
    {
        // ..
    }

 * @endcode
 *
 * @param stream        the stream
 * @param data          the data
 * @param size          the size
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_need(tb_stream_ref_t stream, tb_byte_t** data, tb_size_t size);

/*! seek stream
 *
 * @param stream        the stream
 * @param offset        the offset
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_seek(tb_stream_ref_t stream, tb_hize_t offset);

/*! skip stream
 *
 * @param stream        the stream
 * @param size          the size
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_skip(tb_stream_ref_t stream, tb_hize_t size);

/*! block writ format data
 *
 * @param stream        the stream
 * @param fmt           the format
 *
 * @return              the real size, failed: -1
 */
tb_long_t               tb_stream_printf(tb_stream_ref_t stream, tb_char_t const* fmt, ...);

/*! block read line 
 *
 * @code
 *
    // read line
    tb_long_t size = 0;
    tb_char_t line[8192];
    while ((size = tb_stream_bread_line(stream, line, sizeof(line))) >= 0)
    {
        // trace
        tb_trace_i("line: %s", line);
    }
 *
 * @endcode
 *
 * @param stream        the stream
 * @param data          the data
 * @param size          the size
 *
 * @return              the real size
 */
tb_long_t               tb_stream_bread_line(tb_stream_ref_t stream, tb_char_t* data, tb_size_t size);

/*! block writ line 
 *
 * @param stream        the stream
 * @param data          the data
 * @param size          the size
 *
 * @return              the real size
 */
tb_long_t               tb_stream_bwrit_line(tb_stream_ref_t stream, tb_char_t* data, tb_size_t size);

/*! block read all data 
 *
 * @code
 *
    // read all data
    tb_size_t    size = 0;
    tb_byte_t*   data = tb_stream_bread_all(stream, tb_false, &size);
    if (data)
    {
        // exit data
        tb_free(data);
    }

    // read all cstr and append '\0'
    tb_size_t    size = 0;
    tb_char_t*   cstr = (tb_char_t*)tb_stream_bread_all(stream, tb_true, &size);
    if (cstr)
    {
        // exit cstr
        tb_free(cstr);
    }
  
 * @endcode
 *
 * @param stream        the stream
 * @param is_cstr       will append '\0' if be c-string
 * @param psize         the size pointer, optional
 *
 * @return              the data 
 */
tb_byte_t*              tb_stream_bread_all(tb_stream_ref_t stream, tb_bool_t is_cstr, tb_size_t* psize);

/*! block read uint8 integer
 *
 * @param stream        the stream
 *
 * @return              the uint8 integer
 */
tb_uint8_t              tb_stream_bread_u8(tb_stream_ref_t stream);

/*! block read sint8 integer
 *
 * @param stream        the stream
 *
 * @return              the sint8 integer
 */
tb_sint8_t              tb_stream_bread_s8(tb_stream_ref_t stream);

/*! block read uint16-le integer
 *
 * @param stream        the stream
 *
 * @return              the uint16-le integer
 */
tb_uint16_t             tb_stream_bread_u16_le(tb_stream_ref_t stream);

/*! block read sint16-le integer
 *
 * @param stream        the stream
 *
 * @return              the sint16-le integer
 */
tb_sint16_t             tb_stream_bread_s16_le(tb_stream_ref_t stream);

/*! block read uint24-le integer
 *
 * @param stream        the stream
 *
 * @return              the uint24-le integer
 */
tb_uint32_t             tb_stream_bread_u24_le(tb_stream_ref_t stream);

/*! block read sint24-le integer
 *
 * @param stream        the stream
 *
 * @return              the sint24-le integer
 */
tb_sint32_t             tb_stream_bread_s24_le(tb_stream_ref_t stream);

/*! block read uint32-le integer
 *
 * @param stream        the stream
 *
 * @return              the uint32-le integer
 */
tb_uint32_t             tb_stream_bread_u32_le(tb_stream_ref_t stream);

/*! block read sint32-le integer
 *
 * @param stream        the stream
 *
 * @return              the sint32-le integer
 */
tb_sint32_t             tb_stream_bread_s32_le(tb_stream_ref_t stream);

/*! block read uint64-le integer
 *
 * @param stream        the stream
 *
 * @return              the uint64-le integer
 */
tb_uint64_t             tb_stream_bread_u64_le(tb_stream_ref_t stream);

/*! block read sint64-le integer
 *
 * @param stream        the stream
 *
 * @return              the sint64-le integer
 */
tb_sint64_t             tb_stream_bread_s64_le(tb_stream_ref_t stream);

/*! block read uint16-be integer
 *
 * @param stream        the stream
 *
 * @return              the uint16-be integer
 */
tb_uint16_t             tb_stream_bread_u16_be(tb_stream_ref_t stream);

/*! block read sint16-be integer
 *
 * @param stream        the stream
 *
 * @return              the sint16-be integer
 */
tb_sint16_t             tb_stream_bread_s16_be(tb_stream_ref_t stream);

/*! block read uint24-be integer
 *
 * @param stream        the stream
 *
 * @return              the uint24-be integer
 */
tb_uint32_t             tb_stream_bread_u24_be(tb_stream_ref_t stream);

/*! block read sint24-be integer
 *
 * @param stream        the stream
 *
 * @return              the sint24-be integer
 */
tb_sint32_t             tb_stream_bread_s24_be(tb_stream_ref_t stream);

/*! block read uint32-be integer
 *
 * @param stream        the stream
 *
 * @return              the uint32-be integer
 */
tb_uint32_t             tb_stream_bread_u32_be(tb_stream_ref_t stream);

/*! block read sint32-be integer
 *
 * @param stream        the stream
 *
 * @return              the sint32-be integer
 */
tb_sint32_t             tb_stream_bread_s32_be(tb_stream_ref_t stream);

/*! block read uint64-be integer
 *
 * @param stream        the stream
 *
 * @return              the uint64-be integer
 */
tb_uint64_t             tb_stream_bread_u64_be(tb_stream_ref_t stream);

/*! block read sint64-be integer
 *
 * @param stream        the stream
 *
 * @return              the sint64-be integer
 */
tb_sint64_t             tb_stream_bread_s64_be(tb_stream_ref_t stream);

/*! block writ uint8 integer
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_u8(tb_stream_ref_t stream, tb_uint8_t val);

/*! block writ sint8 integer
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_s8(tb_stream_ref_t stream, tb_sint8_t val);

/*! block writ uint16-le integer
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_u16_le(tb_stream_ref_t stream, tb_uint16_t val);

/*! block writ sint16-le integer
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_s16_le(tb_stream_ref_t stream, tb_sint16_t val);

/*! block writ uint24-le integer
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_u24_le(tb_stream_ref_t stream, tb_uint32_t val);

/*! block writ sint24-le integer
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_s24_le(tb_stream_ref_t stream, tb_sint32_t val);

/*! block writ uint32-le integer
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_u32_le(tb_stream_ref_t stream, tb_uint32_t val);

/*! block writ sint32-le integer
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_s32_le(tb_stream_ref_t stream, tb_sint32_t val);

/*! block writ uint64-le integer
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_u64_le(tb_stream_ref_t stream, tb_uint64_t val);

/*! block writ sint64-le integer
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_s64_le(tb_stream_ref_t stream, tb_sint64_t val);

/*! block writ uint16-be integer
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_u16_be(tb_stream_ref_t stream, tb_uint16_t val);

/*! block writ sint16-be integer
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_s16_be(tb_stream_ref_t stream, tb_sint16_t val);

/*! block writ uint24-be integer
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_u24_be(tb_stream_ref_t stream, tb_uint32_t val);

/*! block writ sint24-be integer
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_s24_be(tb_stream_ref_t stream, tb_sint32_t val);

/*! block writ uint32-be integer
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_u32_be(tb_stream_ref_t stream, tb_uint32_t val);

/*! block writ sint32-be integer
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_s32_be(tb_stream_ref_t stream, tb_sint32_t val);

/*! block writ uint64-be integer
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_u64_be(tb_stream_ref_t stream, tb_uint64_t val);

/*! block writ sint64-be integer
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_s64_be(tb_stream_ref_t stream, tb_sint64_t val);

#ifdef TB_CONFIG_TYPE_HAVE_FLOAT

/*! read float-le number
 *
 * @param stream        the stream
 *
 * @return              the float-le number
 */
tb_float_t              tb_stream_bread_float_le(tb_stream_ref_t stream);

/*! read float-be number
 *
 * @param stream        the stream
 *
 * @return              the float-be number
 */
tb_float_t              tb_stream_bread_float_be(tb_stream_ref_t stream);

/*! read double-ble number
 *
 * @param stream        the stream
 *
 * @return              the double-ble number
 */
tb_double_t             tb_stream_bread_double_ble(tb_stream_ref_t stream);

/*! read double-bbe number
 *
 * @param stream        the stream
 *
 * @return              the double-bbe number
 */
tb_double_t             tb_stream_bread_double_bbe(tb_stream_ref_t stream);

/*! read double-lle number
 *
 * @param stream        the stream
 *
 * @return              the double-lle number
 */
tb_double_t             tb_stream_bread_double_lle(tb_stream_ref_t stream);

/*! read double-lbe number
 *
 * @param stream        the stream
 *
 * @return              the double-lbe number
 */
tb_double_t             tb_stream_bread_double_lbe(tb_stream_ref_t stream);

/*! writ float-le number
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_float_le(tb_stream_ref_t stream, tb_float_t val);

/*! writ float-be number
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_float_be(tb_stream_ref_t stream, tb_float_t val);

/*! writ double-ble number
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_double_ble(tb_stream_ref_t stream, tb_double_t val);

/*! writ double-bbe number
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_double_bbe(tb_stream_ref_t stream, tb_double_t val);

/*! writ double-lle number
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_double_lle(tb_stream_ref_t stream, tb_double_t val);

/*! writ double-lbe number
 *
 * @param stream        the stream
 * @param val           the value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_stream_bwrit_double_lbe(tb_stream_ref_t stream, tb_double_t val);

#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
