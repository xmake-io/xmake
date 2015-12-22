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
 * @file        url.h
 * @ingroup     network
 *
 */
#ifndef TB_NETWORK_URL_H
#define TB_NETWORK_URL_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "ipaddr.h"
#include "../string/string.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the url protocol type
typedef enum __tb_url_protocol_t
{
    TB_URL_PROTOCOL_NONE    = 0
,   TB_URL_PROTOCOL_FILE    = 1     //!< file://... 
,   TB_URL_PROTOCOL_SOCK    = 2     //!< sock://... or socks://...
,   TB_URL_PROTOCOL_HTTP    = 3     //!< http://... or https://...
,   TB_URL_PROTOCOL_DATA    = 4     //!< data://... 
,   TB_URL_PROTOCOL_RTSP    = 5     //!< rtsp://... 
,   TB_URL_PROTOCOL_SQL     = 6     //!< sql://... 

}tb_url_protocol_t;

/// the url type
typedef struct __tb_url_t
{
    // the protocol 
    tb_uint16_t         poto:   6;

    // is ssl?
    tb_uint16_t         bssl:   1;

    // is win?
    tb_uint16_t         bwin:   1;

    // the windows prefix 
    tb_uint16_t         pwin:   8;

    // the addr
    tb_ipaddr_t         addr;

    // the host
    tb_string_t         host;

    // the path
    tb_string_t         path;

    // the args
    tb_string_t         args;

    // the url cache
    tb_string_t         cache;

}tb_url_t, *tb_url_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init url
 *
 * @param url       the url
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_url_init(tb_url_ref_t url);

/*! exit url
 *
 * @param url       the url
 */
tb_void_t           tb_url_exit(tb_url_ref_t url);

/*! clear url
 *
 * @param url       the url
 */
tb_void_t           tb_url_clear(tb_url_ref_t url);

/*! get the url c-string
 *
 * @param url       the url
 *
 * @return          the c-string
 */
tb_char_t const*    tb_url_cstr(tb_url_ref_t url);

/*! set the url c-string
 *
 * @param url       the url
 * @param cstr      the url c-string
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_url_cstr_set(tb_url_ref_t url, tb_char_t const* cstr);

/*! copy the url 
 *
 * @param url       the url
 * @param copy      the copied url
 */
tb_void_t           tb_url_copy(tb_url_ref_t url, tb_url_ref_t copy);

/*! is ssl?
 *
 * @param url       the url
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_url_ssl(tb_url_ref_t url);

/*! set ssl
 *
 * @param url       the url
 * @param bssl      is ssl?
 */
tb_void_t           tb_url_ssl_set(tb_url_ref_t url, tb_bool_t bssl);

/*! get the protocol from the url
 *
 * @param url       the url
 *
 * @return          the url protocol
 */
tb_size_t           tb_url_protocol(tb_url_ref_t url);

/*! set the protocol to the url
 *
 * @param url       the url
 * @param poto      the url protocol
 */
tb_void_t           tb_url_protocol_set(tb_url_ref_t url, tb_size_t protocol);

/*! the protocol c-string
 *
 * @param url       the url
 *
 * @return          the url protocol c-string
 */
tb_char_t const*    tb_url_protocol_cstr(tb_url_ref_t url);

/*! probe the protocol from the url
 *
 * @param url       the url
 *
 * @return          the url protocol
 */
tb_size_t           tb_url_protocol_probe(tb_char_t const* url);

/*! get the port from the url
 *
 * @param url       the url
 *
 * @return          the url port
 */
tb_uint16_t         tb_url_port(tb_url_ref_t url);

/*! set the port to the url
 *
 * @param url       the url
 * @param port      the url port
 */
tb_void_t           tb_url_port_set(tb_url_ref_t url, tb_uint16_t port);

/*! get the address from the url
 *
 * @param url       the url
 *
 * @return          the url address
 */
tb_ipaddr_ref_t     tb_url_addr(tb_url_ref_t url);

/*! set the address to the url
 *
 * @param url       the url
 * @param addr      the url address
 */
tb_void_t           tb_url_addr_set(tb_url_ref_t url, tb_ipaddr_ref_t addr);

/*! get the host from the url
 *
 * @param url       the url
 *
 * @return          the url host
 */
tb_char_t const*    tb_url_host(tb_url_ref_t url);

/*! set the host to the url
 *
 * @param url       the url
 * @param host      the url host
 */
tb_void_t           tb_url_host_set(tb_url_ref_t url, tb_char_t const* host);

/*! get the path from the url
 *
 * @param url       the url
 *
 * @return          the url path
 */
tb_char_t const*    tb_url_path(tb_url_ref_t url);

/*! set the path to the url
 *
 * @param url       the url
 * @param path      the url path
 */
tb_void_t           tb_url_path_set(tb_url_ref_t url, tb_char_t const* path);

/*! get the arguments from the url
 *
 * @param url       the url
 *
 * @return          the url arguments
 */
tb_char_t const*    tb_url_args(tb_url_ref_t url);

/*! set the arguments to the url
 *
 * @param url       the url
 * @param args      the url arguments
 */
tb_void_t           tb_url_args_set(tb_url_ref_t url, tb_char_t const* args);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__


#endif
