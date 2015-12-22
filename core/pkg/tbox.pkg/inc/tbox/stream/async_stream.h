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
 * @file        async_stream.h
 * @ingroup     stream
 *
 */
#ifndef TB_STREAM_ASYNC_STREAM_H
#define TB_STREAM_ASYNC_STREAM_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../asio/asio.h"
#include "../libc/libc.h"
#include "../network/url.h"
#include "../memory/memory.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/// open
#define tb_async_stream_open(stream, func, priv)                                    tb_async_stream_open_(stream, func, priv __tb_debug_vals__)

/// clos
#define tb_async_stream_clos(stream, func, priv)                                    tb_async_stream_clos_(stream, func, priv __tb_debug_vals__)

/// read
#define tb_async_stream_read(stream, size, func, priv)                              tb_async_stream_read_(stream, size, func, priv __tb_debug_vals__)

/// writ
#define tb_async_stream_writ(stream, data, size, func, priv)                        tb_async_stream_writ_(stream, data, size, func, priv __tb_debug_vals__)

/// seek
#define tb_async_stream_seek(stream, offset, func, priv)                            tb_async_stream_seek_(stream, offset, func, priv __tb_debug_vals__)

/// sync
#define tb_async_stream_sync(stream, bclosing, func, priv)                          tb_async_stream_sync_(stream, bclosing, func, priv __tb_debug_vals__)

/// task
#define tb_async_stream_task(stream, delay, func, priv)                             tb_async_stream_task_(stream, delay, func, priv __tb_debug_vals__)

/// open and read
#define tb_async_stream_open_read(stream, size, func, priv)                         tb_async_stream_open_read_(stream, size, func, priv __tb_debug_vals__)

/// open and writ
#define tb_async_stream_open_writ(stream, data, size, func, priv)                   tb_async_stream_open_writ_(stream, data, size, func, priv __tb_debug_vals__)

/// open and seek
#define tb_async_stream_open_seek(stream, offset, func, priv)                       tb_async_stream_open_seek_(stream, offset, func, priv __tb_debug_vals__)

/// read after delay
#define tb_async_stream_read_after(stream, delay, size, func, priv)                 tb_async_stream_read_after_(stream, delay, size, func, priv __tb_debug_vals__)

/// writ after delay
#define tb_async_stream_writ_after(stream, delay, data, size, func, priv)           tb_async_stream_writ_after_(stream, delay, data, size, func, priv __tb_debug_vals__)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the stream open func type
 *
 * @param stream                the stream
 * @param state                 the state
 * @param priv                  the func private data
 *
 * @return                      tb_true: ok, tb_false: error, but not break aicp
 */
typedef tb_bool_t               (*tb_async_stream_open_func_t)(tb_async_stream_ref_t stream, tb_size_t state, tb_cpointer_t priv);

/*! the stream clos func type
 *
 * @param stream                the stream
 * @param state                 the state
 * @param priv                  the func private data
 */
typedef tb_void_t               (*tb_async_stream_clos_func_t)(tb_async_stream_ref_t stream, tb_size_t state, tb_cpointer_t priv);

/*! the stream read func type
 *
 * @param stream                the stream
 * @param state                 the state
 * @param data                  the readed data
 * @param real                  the real size, maybe zero
 * @param size                  the need size
 * @param priv                  the func private data
 *
 * @return                      tb_true: ok and continue it if need, tb_false: break it, but not break aicp
 */
typedef tb_bool_t               (*tb_async_stream_read_func_t)(tb_async_stream_ref_t stream, tb_size_t state, tb_byte_t const* data, tb_size_t real, tb_size_t size, tb_cpointer_t priv);

/*! the stream writ func type
 *
 * @param stream                the stream
 * @param state                 the state
 * @param data                  the writed data
 * @param real                  the real size, maybe zero
 * @param size                  the need size
 * @param priv                  the func private data
 *
 * @return                      tb_true: ok and continue it if need, tb_false: break it, but not break aicp
 */
typedef tb_bool_t               (*tb_async_stream_writ_func_t)(tb_async_stream_ref_t stream, tb_size_t state, tb_byte_t const* data, tb_size_t real, tb_size_t size, tb_cpointer_t priv);

/*! the stream seek func type
 *
 * @param stream                the stream
 * @param state                 the state
 * @param offset                the real offset
 * @param priv                  the func private data
 *
 * @return                      tb_true: ok, tb_false: error, but not break aicp
 */
typedef tb_bool_t               (*tb_async_stream_seek_func_t)(tb_async_stream_ref_t stream, tb_size_t state, tb_hize_t offset, tb_cpointer_t priv);

/*! the stream sync func type
 *
 * @param stream                the stream
 * @param state                 the state
 * @param bclosing              is closing?
 * @param priv                  the func private data
 *
 * @return                      tb_true: ok, tb_false: error, but not break aicp
 */
typedef tb_bool_t               (*tb_async_stream_sync_func_t)(tb_async_stream_ref_t stream, tb_size_t state, tb_bool_t bclosing, tb_cpointer_t priv);

/*! the stream task func type
 *
 * @param stream                the stream
 * @param state                 the state
 * @param priv                  the func private data
 *
 * @return                      tb_true: ok, tb_false: error, but not break aicp
 */
typedef tb_bool_t               (*tb_async_stream_task_func_t)(tb_async_stream_ref_t stream, tb_size_t state, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init async stream 
 *
 * @param aicp          the aicp
 * @param type          the stream type
 * @param type_size     the stream type size
 * @param rcache        the read cache size
 * @param wcache        the writ cache size
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
    // the custom xxxx async stream type
    typedef struct __tb_async_stream_xxxx_impl_t
    {
        // the xxxx data
        tb_handle_t         xxxx;

    }tb_async_stream_xxxx_impl_t;

    static tb_bool_t tb_async_stream_xxxx_impl_open(tb_async_stream_ref_t stream, tb_async_stream_open_func_t func, tb_cpointer_t priv)
    {
        // check
        tb_async_stream_xxxx_impl_t* impl = (tb_async_stream_xxxx_impl_t*)stream;
        tb_assert_and_check_return_val(impl, tb_false);

        // ok
        return tb_true;
    }
    static tb_bool_t tb_async_stream_xxxx_impl_clos(tb_async_stream_ref_t stream, tb_async_stream_clos_func_t, tb_cpointer_t priv)
    {
        // check
        tb_async_stream_xxxx_impl_t* impl = (tb_async_stream_xxxx_impl_t*)stream;
        tb_assert_and_check_return_val(impl, tb_false);

        // ok
        return tb_true;
    }

    // define other xxxx async stream func
    // ...

    // init async stream
    tb_async_stream_ref_t stream = tb_async_stream_init(    tb_aicp()
                                                        ,   TB_STREAM_TYPE_XXXX
                                                        ,   sizeof(tb_async_stream_xxxx_impl_t)
                                                        ,   0
                                                        ,   0
                                                        ,   tb_async_stream_xxxx_impl_open_try
                                                        ,   tb_async_stream_xxxx_impl_clos_try
                                                        ,   tb_async_stream_xxxx_impl_open
                                                        ,   tb_async_stream_xxxx_impl_clos
                                                        ,   tb_async_stream_xxxx_impl_exit
                                                        ,   tb_async_stream_xxxx_impl_kill
                                                        ,   tb_async_stream_xxxx_impl_ctrl
                                                        ,   tb_async_stream_xxxx_impl_read
                                                        ,   tb_async_stream_xxxx_impl_writ
                                                        ,   tb_async_stream_xxxx_impl_seek
                                                        ,   tb_async_stream_xxxx_impl_sync
                                                        ,   tb_async_stream_xxxx_impl_task
                                                        );

    // using async stream
    // ...

 * @endcode
 */
tb_async_stream_ref_t   tb_async_stream_init(   tb_aicp_ref_t aicp
                                            ,   tb_size_t type
                                            ,   tb_size_t type_size
                                            ,   tb_size_t rcache
                                            ,   tb_size_t wcache
                                            ,   tb_bool_t (*open_try)(tb_async_stream_ref_t stream)
                                            ,   tb_bool_t (*clos_try)(tb_async_stream_ref_t stream)
                                            ,   tb_bool_t (*open)(tb_async_stream_ref_t stream, tb_async_stream_open_func_t func, tb_cpointer_t priv)
                                            ,   tb_bool_t (*clos)(tb_async_stream_ref_t stream, tb_async_stream_clos_func_t func, tb_cpointer_t priv)
                                            ,   tb_bool_t (*exit)(tb_async_stream_ref_t stream)
                                            ,   tb_void_t (*kill)(tb_async_stream_ref_t stream)
                                            ,   tb_bool_t (*ctrl)(tb_async_stream_ref_t stream, tb_size_t ctrl, tb_va_list_t args)
                                            ,   tb_bool_t (*read)(tb_async_stream_ref_t stream, tb_size_t delay, tb_byte_t* data, tb_size_t size, tb_async_stream_read_func_t func, tb_cpointer_t priv)
                                            ,   tb_bool_t (*writ)(tb_async_stream_ref_t stream, tb_size_t delay, tb_byte_t const* data, tb_size_t size, tb_async_stream_writ_func_t func, tb_cpointer_t priv)
                                            ,   tb_bool_t (*seek)(tb_async_stream_ref_t stream, tb_hize_t offset, tb_async_stream_seek_func_t func, tb_cpointer_t priv)
                                            ,   tb_bool_t (*sync)(tb_async_stream_ref_t stream, tb_bool_t bclosing, tb_async_stream_sync_func_t func, tb_cpointer_t priv)
                                            ,   tb_bool_t (*task)(tb_async_stream_ref_t stream, tb_size_t delay, tb_async_stream_task_func_t func, tb_cpointer_t priv));

/*! init data stream 
 *
 * @param aicp          the aicp, using the default aicp if be null
 *
 * @return              the stream
 */
tb_async_stream_ref_t   tb_async_stream_init_data(tb_aicp_ref_t aicp);

/*! init file stream 
 *
 * @param aicp          the aicp, using the default aicp if be null
 *
 * @return              the stream
 */
tb_async_stream_ref_t   tb_async_stream_init_file(tb_aicp_ref_t aicp);

/*! init sock stream 
 *
 * @param aicp          the aicp, using the default aicp if be null
 *
 * @return              the stream
 */
tb_async_stream_ref_t   tb_async_stream_init_sock(tb_aicp_ref_t aicp);

/*! init http stream 
 *
 * @param aicp          the aicp, using the default aicp if be null
 *
 * @return              the stream
 */
tb_async_stream_ref_t   tb_async_stream_init_http(tb_aicp_ref_t aicp);

/*! init filter stream 
 *
 * @param aicp          the aicp, using the default aicp if be null
 *
 * @return              the stream
 */
tb_async_stream_ref_t   tb_async_stream_init_filter(tb_aicp_ref_t aicp);

/*! exit stream
 *
 * @param stream        the stream
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_stream_exit(tb_async_stream_ref_t stream);

/*! init stream from url
 *
 * @param aicp          the aicp, using the default aicp if be null
 * @param url           the url
 * <pre>
 * data://base64
 * file://path or unix path: e.g. /root/xxxx/file
 * sock://host:port?tcp=
 * sock://host:port?udp=
 * socks://host:port
 * http://host:port/path?arg0=&arg1=...
 * https://host:port/path?arg0=&arg1=...
 * </pre>
 *
 * @return              the stream
 */
tb_async_stream_ref_t   tb_async_stream_init_from_url(tb_aicp_ref_t aicp, tb_char_t const* url);

/*! init stream from data
 *
 * @param aicp          the aicp, using the default aicp if be null
 * @param data          the data
 * @param size          the size
 *
 * @return              the stream
 */
tb_async_stream_ref_t   tb_async_stream_init_from_data(tb_aicp_ref_t aicp, tb_byte_t const* data, tb_size_t size);

/*! init stream from file
 *
 * @param aicp          the aicp, using the default aicp if be null
 * @param path          the file path
 * @param mode          the file mode, using the default ro mode if zero
 *
 * @return              the stream
 */
tb_async_stream_ref_t   tb_async_stream_init_from_file(tb_aicp_ref_t aicp, tb_char_t const* path, tb_size_t mode);

/*! init stream from sock
 *
 * @param aicp          the aicp, using the default aicp if be null
 * @param host          the host
 * @param port          the port
 * @param type          the socket type, tcp or udp
 * @param bssl          enable ssl?
 *
 * @return              the stream
 */
tb_async_stream_ref_t   tb_async_stream_init_from_sock(tb_aicp_ref_t aicp, tb_char_t const* host, tb_uint16_t port, tb_size_t type, tb_bool_t bssl);

/*! init stream from http or https
 *
 * @param aicp          the aicp, using the default aicp if be null
 * @param host          the host
 * @param port          the port
 * @param path          the path
 * @param bssl          enable ssl?
 *
 * @return              the stream
 */
tb_async_stream_ref_t   tb_async_stream_init_from_http(tb_aicp_ref_t aicp, tb_char_t const* host, tb_uint16_t port, tb_char_t const* path, tb_bool_t bssl);

/*! init filter stream from null
 *
 * @param stream        the stream
 *
 * @return              the stream
 */
tb_async_stream_ref_t   tb_async_stream_init_filter_from_null(tb_async_stream_ref_t stream);

/*! init filter stream from zip
 *
 * @param stream        the stream
 * @param algo          the zip algorithm
 * @param action        the zip action
 *
 * @return              the stream
 */
tb_async_stream_ref_t   tb_async_stream_init_filter_from_zip(tb_async_stream_ref_t stream, tb_size_t algo, tb_size_t action);

/*! init filter stream from cache
 *
 * @param stream        the stream
 * @param size          the initial cache size, using the default size if be zero
 *
 * @return              the stream
 */
tb_async_stream_ref_t   tb_async_stream_init_filter_from_cache(tb_async_stream_ref_t stream, tb_size_t size);

/*! init filter stream from charset
 *
 * @param stream        the stream
 * @param fr            the from charset
 * @param to            the to charset
 *
 * @return              the stream
 */
tb_async_stream_ref_t   tb_async_stream_init_filter_from_charset(tb_async_stream_ref_t stream, tb_size_t fr, tb_size_t to);

/*! init filter stream from chunked
 *
 * @param stream        the stream
 * @param dechunked     decode the chunked data?
 *
 * @return              the stream
 */
tb_async_stream_ref_t   tb_async_stream_init_filter_from_chunked(tb_async_stream_ref_t stream, tb_bool_t dechunked);

/*! the stream url
 *
 * @param stream        the stream
 *
 * @return              the stream url
 */
tb_url_ref_t               tb_async_stream_url(tb_async_stream_ref_t stream);

/*! the stream type
 *
 * @param stream        the stream
 *
 * @return              the stream type
 */
tb_size_t               tb_async_stream_type(tb_async_stream_ref_t stream);

/*! the stream size and not seeking it
 *
 * @param stream        the stream
 *
 * @return              the stream size, no size: -1, empty or error: 0
 */
tb_hong_t               tb_async_stream_size(tb_async_stream_ref_t stream);

/*! the stream left size and not seeking it 
 *
 * @param stream        the stream
 *
 * @return              the stream left size, no size: infinity, empty or end: 0
 */
tb_hize_t               tb_async_stream_left(tb_async_stream_ref_t stream);

/*! the stream is end?
 *
 * @param stream        the stream
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_stream_beof(tb_async_stream_ref_t stream);

/*! the stream offset
 *
 * the offset is read + writ and using seek for modifying it if size != -1, .e.g: data, file, .. 
 * the offset is calculated from the last read/writ and not seeking it if size == -1, .e.g: sock, filter, ..
 *
 * @param stream        the stream
 *
 * @return              the stream offset
 */
tb_hize_t               tb_async_stream_offset(tb_async_stream_ref_t stream);

/*! is opened?
 *
 * @param stream        the stream
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_stream_is_opened(tb_async_stream_ref_t stream);

/*! is closed?
 *
 * @param stream        the stream
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_stream_is_closed(tb_async_stream_ref_t stream);

/*! is killed?
 *
 * @param stream        the stream
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_stream_is_killed(tb_async_stream_ref_t stream);

/*! the stream timeout
 *
 * @param stream        the stream
 *
 * @return              the stream timeout
 */
tb_long_t               tb_async_stream_timeout(tb_async_stream_ref_t stream);

/*! ctrl stream
 *
 * @param stream        the stream
 * @param ctrl          the ctrl code
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_stream_ctrl(tb_async_stream_ref_t stream, tb_size_t ctrl, ...);

/*! ctrl stream with arguments
 *
 * @param stream        the stream
 * @param ctrl          the ctrl code
 * @param args          the ctrl args
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_stream_ctrl_with_args(tb_async_stream_ref_t stream, tb_size_t ctrl, tb_va_list_t args);

/*! kill stream
 *
 * @param stream        the stream
 */
tb_void_t               tb_async_stream_kill(tb_async_stream_ref_t stream);

/*! try opening the stream for stream: file, filter, ... 
 *
 * @param stream        the stream
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_stream_open_try(tb_async_stream_ref_t stream);

/*! open the stream 
 *
 * @param stream        the stream
 * @param func          the func
 * @param priv          the func data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_stream_open_(tb_async_stream_ref_t stream, tb_async_stream_open_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! try closing the stream for stream: file, filter, or closed stream... 
 *
 * @param stream        the stream
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_stream_clos_try(tb_async_stream_ref_t stream);

/*! close the stream
 *
 * @param stream        the stream
 * @param func          the func
 * @param priv          the func data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_stream_clos_(tb_async_stream_ref_t stream, tb_async_stream_clos_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! read the stream 
 *
 * @param stream        the stream
 * @param size          the read size, using the default size if be zero
 * @param func          the func
 * @param priv          the func data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_stream_read_(tb_async_stream_ref_t stream, tb_size_t size, tb_async_stream_read_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! writ the stream 
 *
 * @param stream        the stream
 * @param data          the data
 * @param size          the size
 * @param func          the func
 * @param priv          the func data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_stream_writ_(tb_async_stream_ref_t stream, tb_byte_t const* data, tb_size_t size, tb_async_stream_writ_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! seek the stream
 *
 * @param stream        the stream
 * @param offset        the offset
 * @param func          the func
 * @param priv          the func data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_stream_seek_(tb_async_stream_ref_t stream, tb_hize_t offset, tb_async_stream_seek_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! sync the stream
 *
 * @param stream        the stream
 * @param bclosing      sync the tail data for closing
 * @param func          the func
 * @param priv          the func data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_stream_sync_(tb_async_stream_ref_t stream, tb_bool_t bclosing, tb_async_stream_sync_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! task the stream
 *
 * @param stream        the stream
 * @param delay         the delay time, ms
 * @param func          the func
 * @param priv          the func data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_stream_task_(tb_async_stream_ref_t stream, tb_size_t delay, tb_async_stream_task_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! open and read the stream, open it first if not opened 
 *
 * @param stream        the stream
 * @param size          the read size, using the default size if be zero
 * @param func          the func
 * @param priv          the func data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_stream_read_(tb_async_stream_ref_t stream, tb_size_t size, tb_async_stream_read_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! open and read the stream, open it first if not opened 
 *
 * @param stream        the stream
 * @param size          the size, using the default size be zero
 * @param func          the func
 * @param priv          the func data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_stream_open_read_(tb_async_stream_ref_t stream, tb_size_t size, tb_async_stream_read_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! open and writ the stream, open it first if not opened 
 *
 * @param stream        the stream
 * @param data          the data
 * @param size          the size
 * @param func          the func
 * @param priv          the func data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_stream_open_writ_(tb_async_stream_ref_t stream, tb_byte_t const* data, tb_size_t size, tb_async_stream_writ_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! open and seek the stream, open it first if not opened 
 *
 * @param stream        the stream
 * @param offset        the offset
 * @param func          the func
 * @param priv          the func data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_stream_open_seek_(tb_async_stream_ref_t stream, tb_hize_t offset, tb_async_stream_seek_func_t func, tb_cpointer_t priv __tb_debug_decl__);
    
/*! read the stream after the delay time
 *
 * @param stream        the stream
 * @param delay         the delay time, ms
 * @param size          the read size, using the default size if be zero
 * @param func          the func
 * @param priv          the func data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_stream_read_after_(tb_async_stream_ref_t stream, tb_size_t delay, tb_size_t size, tb_async_stream_read_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! writ the stream after the delay time
 *
 * @param stream        the stream
 * @param delay         the delay time, ms
 * @param data          the data
 * @param size          the size
 * @param func          the func
 * @param priv          the func data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_stream_writ_after_(tb_async_stream_ref_t stream, tb_size_t delay, tb_byte_t const* data, tb_size_t size, tb_async_stream_writ_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! the stream aicp
 *
 * @param stream        the stream
 *
 * @return              the stream aicp
 */
tb_aicp_ref_t           tb_async_stream_aicp(tb_async_stream_ref_t stream);

#ifdef __tb_debug__
/*! the stream func name from post for debug
 *
 * @param stream        the stream
 *
 * @return              the stream func name
 */
tb_char_t const*        tb_async_stream_func(tb_async_stream_ref_t stream);

/*! the stream file name from post for debug
 *
 * @param stream        the stream
 *
 * @return              the stream file name
 */
tb_char_t const*        tb_async_stream_file(tb_async_stream_ref_t stream);

/*! the stream line number from post for debug
 *
 * @param stream        the stream
 *
 * @return              the stream line number
 */
tb_size_t               tb_async_stream_line(tb_async_stream_ref_t stream);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
