/*!The Treasure Box Library
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * Copyright (C) 2009 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        url.c
 * @ingroup     network
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "url"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "url.h"
#include "http.h"
#include "impl/http/prefix.h"
#include "../libc/libc.h"
#include "../math/math.h"
#include "../utils/utils.h"
#include "../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_char_t const* tb_url_parse_args(tb_string_ref_t args, tb_char_t const* p)
{
    // check
    tb_assert_and_check_return_val(args && p, tb_null);

    // clear args
    tb_string_clear(args);

    // skip '?' or ' '
    while (*p && (*p == '?' || tb_isspace(*p))) p++;

    // done
    while (*p) tb_string_chrcat(args, *p++);

    // end
    return p;
}
static tb_char_t const* tb_url_parse_path(tb_string_ref_t path, tb_char_t const* p)
{
    // check
    tb_assert_and_check_return_val(path && p, tb_null);

    // clear path
    tb_string_clear(path);

    // skip ' '
    while (*p && tb_isspace(*p)) p++;

    // append root: '/'
    if (*p != '/' && *p != '\\') tb_string_chrcat(path, '/');

    // done
    tb_char_t ch;
    while ((ch = *p) && ch != '?')
    {
        // replace '\\' => '/'
        if (ch == '\\') tb_string_chrcat(path, '/');
        // append character
        else tb_string_chrcat(path, ch);

        // next
        p++;
    }

    // end
    return p;
}
static tb_char_t const* tb_url_parse_host(tb_string_ref_t host, tb_char_t const* p)
{
    // check
    tb_assert_and_check_return_val(host && p, tb_null);

    // clear path
    tb_string_clear(host);

    // ipv6? [xxxx:xxxx:...]:port
    if (*p == '[')
    {
        // skip '['
        p++;

        // parse host
        tb_char_t ch;
        while ((ch = *p) && ch != ']')
        {
            // append character
            tb_string_chrcat(host, ch);

            // next
            p++;
        }

        // append ']'
        if (ch == ']') p++;
    }
    else
    {
        // parse host
        tb_char_t ch;
        while ((ch = *p) && !tb_isspace(ch) && ch != ':' && ch != '/' && ch != '\\' && ch != '?' && ch != '&')
        {
            // append character
            tb_string_chrcat(host, ch);

            // next
            p++;
        }
    }

    // end
    return p;
}
static tb_char_t const* tb_url_parse_port(tb_uint16_t* port, tb_char_t const* p)
{
    // check
    tb_assert_and_check_return_val(port && p, tb_null);

    // done
    tb_char_t   data[12] = {0};
    tb_char_t*  pb = data;
    tb_char_t*  pe = data + sizeof(data);
    while (pb < pe && *p && tb_isdigit(*p)) *pb++ = *p++;
    *port = (tb_uint16_t)tb_s10tou32(data);

    // end
    return p;
}
static tb_char_t const* tb_url_parse_data(tb_string_ref_t data, tb_char_t const* p)
{
    // check
    tb_assert_and_check_return_val(data && p, tb_null);

    // clear path
    tb_string_clear(data);

    // skip '/' and '\\' and ' ' 
    while (*p && (*p == '/' || *p == '\\' || tb_isspace(*p))) p++;

    // done
    tb_char_t ch;
    while ((ch = *p) && !tb_isspace(ch))
    {
        // append data
        tb_string_chrcat(data, ch);

        // next
        p++;
    }

    // end
    return p;
}
/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_url_init(tb_url_ref_t url)
{
    // check
    tb_assert_and_check_return_val(url, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // init url
        url->poto = TB_URL_PROTOCOL_NONE;
        url->bssl = 0;
        url->bwin = 0;
        url->pwin = 0;
        tb_ipaddr_clear(&url->addr);
        if (!tb_string_init(&url->host)) break;
        if (!tb_string_init(&url->path)) break;
        if (!tb_string_init(&url->args)) break;
        if (!tb_string_init(&url->cache)) break;

        // ok
        ok = tb_true;

    } while (0);

    // failed? exit it
    if (!ok) tb_url_exit(url);

    // ok
    return ok;
}
tb_bool_t tb_url_init_from_cstr(tb_url_ref_t url, tb_char_t const* cstr)
{
    return tb_url_init(url) && tb_url_cstr_set(url, cstr);
}
tb_void_t tb_url_exit(tb_url_ref_t url)
{
    if (url)
    {
        tb_string_exit(&url->host);
        tb_string_exit(&url->path);
        tb_string_exit(&url->args);
        tb_string_exit(&url->cache);
    }
}
tb_void_t tb_url_clear(tb_url_ref_t url)
{
    // check
    tb_assert_and_check_return(url);

    // clear
    url->poto = TB_URL_PROTOCOL_NONE;
    url->bssl = 0;
    url->bwin = 0;
    url->pwin = 0;
    tb_ipaddr_clear(&url->addr);
    tb_string_clear(&url->host);
    tb_string_clear(&url->path);
    tb_string_clear(&url->args);
    tb_string_clear(&url->cache);
}
tb_char_t const* tb_url_cstr(tb_url_ref_t url)
{
    // check
    tb_assert_and_check_return_val(url, tb_null);

    // exists? return it directly
    if (tb_string_size(&url->cache)) return tb_string_cstr(&url->cache);

    // make
    switch (url->poto)
    {
    case TB_URL_PROTOCOL_FILE:
        {
            // check
            tb_check_return_val(tb_string_size(&url->path), tb_null);

            // add protocol
            if (!url->bwin)
            {
                if (url->bssl) tb_string_cstrncpy(&url->cache, "files://", 8);
                else tb_string_cstrncpy(&url->cache, "file://", 7);
            }
            else
            {
                tb_assert(url->pwin);
                tb_string_cstrfcpy(&url->cache, "%c:/", url->pwin);
            }

            // add path
            tb_string_cstrncat(&url->cache, tb_string_cstr(&url->path), tb_string_size(&url->path));
        }
        break;
    case TB_URL_PROTOCOL_SOCK:
    case TB_URL_PROTOCOL_HTTP:
    case TB_URL_PROTOCOL_RTSP:
        {   
            // the port
            tb_uint16_t port = tb_ipaddr_port(&url->addr);

            // check
            tb_check_return_val(port && tb_string_size(&url->host), tb_null);

            // add protocol
            if (url->poto == TB_URL_PROTOCOL_HTTP) tb_string_cstrcpy(&url->cache, "http");
            else if (url->poto == TB_URL_PROTOCOL_SOCK) tb_string_cstrcpy(&url->cache, "sock");
            else if (url->poto == TB_URL_PROTOCOL_RTSP) tb_string_cstrcpy(&url->cache, "rtsp");
            else tb_assert_and_check_break(0);

            // add ssl
            if (url->bssl) tb_string_chrcat(&url->cache, 's');

            // add ://
            tb_string_cstrncat(&url->cache, "://", 3);

            // add host for ipv6
            if (tb_ipaddr_family(&url->addr) == TB_IPADDR_FAMILY_IPV6)
            {
                tb_string_chrcat(&url->cache, '[');
                tb_string_cstrncat(&url->cache, tb_string_cstr(&url->host), tb_string_size(&url->host));
                tb_string_chrcat(&url->cache, ']');
            }
            // add host for ipv4
            else tb_string_cstrncat(&url->cache, tb_string_cstr(&url->host), tb_string_size(&url->host));

            // add port
            if (    (url->poto != TB_URL_PROTOCOL_HTTP)
                ||  (url->bssl && port != TB_HTTP_DEFAULT_PORT_SSL) 
                ||  (!url->bssl && port != TB_HTTP_DEFAULT_PORT))
            {
                tb_string_cstrfcat(&url->cache, ":%u", port);
            }

            // add path
            if (tb_string_size(&url->path)) 
                tb_string_cstrncat(&url->cache, tb_string_cstr(&url->path), tb_string_size(&url->path));

            // add args
            if (tb_string_size(&url->args)) 
            {
                tb_string_chrcat(&url->cache, '?');
                tb_string_strcat(&url->cache, &url->args);
            }
        }
        break;
    case TB_URL_PROTOCOL_SQL:
        {
            // add protocol
            tb_string_cstrcpy(&url->cache, "sql://");

            // add host and port
            if (tb_string_size(&url->host))
            {
                // the port
                tb_uint16_t port = tb_ipaddr_port(&url->addr);

                // add host
                tb_string_cstrncat(&url->cache, tb_string_cstr(&url->host), tb_string_size(&url->host));

                // add port
                if (port) tb_string_cstrfcat(&url->cache, ":%u", port);
            }

            // add path
            if (tb_string_size(&url->path)) 
                tb_string_cstrncat(&url->cache, tb_string_cstr(&url->path), tb_string_size(&url->path));

            // add args
            if (tb_string_size(&url->args)) 
            {
                tb_string_chrcat(&url->cache, '?');
                tb_string_strcat(&url->cache, &url->args);
            }
        }
        break;
    case TB_URL_PROTOCOL_DATA:
        break;
    default:
        break;
    }

    // ok?
    return tb_string_size(&url->cache)? tb_string_cstr(&url->cache) : tb_null;
}
tb_bool_t tb_url_cstr_set(tb_url_ref_t url, tb_char_t const* cstr)
{
    // check
    tb_assert_and_check_return_val(url && cstr, tb_false);
    
    // done
    tb_bool_t ok = tb_false;
    do
    {
        // init
        tb_url_clear(url);

        // parse proto
        tb_char_t const*    p = cstr;
        tb_char_t           full[TB_PATH_MAXN];
        if (!tb_strnicmp(p, "http://", 7)) 
        {
            url->poto = TB_URL_PROTOCOL_HTTP;
            url->bssl = 0;
            p += 7;
        }
        else if (!tb_strnicmp(p, "sock://", 7))
        {
            url->poto = TB_URL_PROTOCOL_SOCK;
            url->bssl = 0;
            p += 7;
        }
        else if (!tb_strnicmp(p, "file://", 7))
        {
            url->poto = TB_URL_PROTOCOL_FILE;
            url->bssl = 0;
            p += 7;
        }
        else if (!tb_strnicmp(p, "rtsp://", 7))
        {
            url->poto = TB_URL_PROTOCOL_RTSP;
            url->bssl = 0;
            p += 7;
        }
        else if (!tb_strnicmp(p, "data://", 7))
        {
            url->poto = TB_URL_PROTOCOL_DATA;
            url->bssl = 0;
            p += 7;
        }
        else if (!tb_strnicmp(p, "https://", 8))
        {
            url->poto = TB_URL_PROTOCOL_HTTP;
            url->bssl = 1;
            p += 8;
        }
        else if (!tb_strnicmp(p, "socks://", 8))
        {
            url->poto = TB_URL_PROTOCOL_SOCK;
            url->bssl = 1;
            p += 8;
        }
        else if (!tb_strnicmp(p, "sql://", 6))
        {
            url->poto = TB_URL_PROTOCOL_SQL;
            url->bssl = 0;
            p += 6;
        }
        // ./file or /home/file or c:/file or c:\\file ...
        else if ((p = tb_path_absolute(cstr, full, TB_PATH_MAXN))) 
        {
            // for unix style path
            if ((*p == '/') || (!tb_strnicmp(p, "file://", 7))) 
            {
                url->poto = TB_URL_PROTOCOL_FILE;
                url->bssl = 0;
                if (*p != '/') p += 7;
            }
            // for windows style path
            else if (tb_isalpha(p[0]) && p[1] == ':' && (p[2] == '/' || p[2] == '\\'))
            {
                url->poto = TB_URL_PROTOCOL_FILE;
                url->bssl = 0;
                url->bwin = 1;
                url->pwin = *p;

                // skip the drive prefix
                p += 3;
            }
            else break;
        }
        else
        {
            // trace
            tb_trace_w("[url]: unknown prefix for url: %s", p);
            break;
        }

        // end?
        tb_assert_and_check_break(*p);

        // parse host and port for http or sock or rtsp
        if (    url->poto == TB_URL_PROTOCOL_HTTP
            ||  url->poto == TB_URL_PROTOCOL_SOCK
            ||  url->poto == TB_URL_PROTOCOL_RTSP
            ||  url->poto == TB_URL_PROTOCOL_SQL)
        {
            // parse host
            p = tb_url_parse_host(&url->host, p);
            tb_assert_and_check_break(p);
        
            // attempt to parse address
            if (tb_string_size(&url->host)) tb_ipaddr_ip_cstr_set(&url->addr, tb_string_cstr(&url->host), TB_IPADDR_FAMILY_NONE);

            // parse port
            tb_uint16_t port = 0;
            if (*p == ':')
            {
                // parse it
                p = tb_url_parse_port(&port, p + 1);
                tb_assert_and_check_break(p);

                // no port? using the default port
                if (!port) port = url->bssl? TB_HTTP_DEFAULT_PORT_SSL : TB_HTTP_DEFAULT_PORT;
            }
            else if (url->poto == TB_URL_PROTOCOL_HTTP) port = url->bssl? TB_HTTP_DEFAULT_PORT_SSL : TB_HTTP_DEFAULT_PORT;
            else if (url->poto != TB_URL_PROTOCOL_SQL) break;

            // save port
            tb_ipaddr_port_set(&url->addr, port);
        }

        // parse path and args 
        if (url->poto != TB_URL_PROTOCOL_DATA)
        {
            // parse path
            p = tb_url_parse_path(&url->path, p);
            tb_assert_and_check_break(p);

            // find args
            while (*p && *p != '?') p++;

            // parse args
            if (*p == '?') tb_url_parse_args(&url->args, p);
        }
        // parse data
        else p = tb_url_parse_data(&url->cache, p);

        // ok
        ok = tb_true;

    } while (0);

    // failed? clear the url
    if (!ok) tb_url_clear(url);

    // ok?
    return ok;
}
tb_void_t tb_url_copy(tb_url_ref_t url, tb_url_ref_t copy)
{
    // check
    tb_assert_and_check_return(url && copy);

    // copy it
    url->poto = copy->poto;
    url->addr = copy->addr;
    url->bssl = copy->bssl;
    url->bwin = copy->bwin;
    url->pwin = copy->pwin;
    tb_string_strcpy(&url->host, &copy->host);
    tb_string_strcpy(&url->path, &copy->path);
    tb_string_strcpy(&url->args, &copy->args);
    tb_string_strcpy(&url->cache, &copy->cache);
}
tb_bool_t tb_url_ssl(tb_url_ref_t url)
{
    // check
    tb_assert_and_check_return_val(url, tb_false);

    // get ssl
    return url->bssl? tb_true : tb_false;
}
tb_void_t tb_url_ssl_set(tb_url_ref_t url, tb_bool_t bssl)
{
    // check
    tb_assert_and_check_return(url);

    // set ssl
    url->bssl = bssl? 1 : 0;
}
tb_size_t tb_url_protocol(tb_url_ref_t url)
{
    // check
    tb_assert_and_check_return_val(url, TB_URL_PROTOCOL_NONE);

    // get protocol
    return url->poto;
}
tb_void_t tb_url_protocol_set(tb_url_ref_t url, tb_size_t poto)
{
    // check
    tb_assert_and_check_return(url);

    // set protocol
    url->poto = poto;
}
tb_char_t const* tb_url_protocol_cstr(tb_url_ref_t url)
{
    // check
    tb_assert_and_check_return_val(url, tb_null);

    // the protocols
    static tb_char_t const* s_protocols[] = 
    {
        tb_null
    ,   "file"
    ,   "sock"
    ,   "http"
    ,   "data"
    ,   "rtsp"
    ,   "sql"
    };
    tb_assert_and_check_return_val(url->poto < tb_arrayn(s_protocols), tb_null);

    // ok
    return s_protocols[url->poto];
}
tb_size_t tb_url_protocol_probe(tb_char_t const* url)
{
    // check
    tb_assert_and_check_return_val(url, TB_URL_PROTOCOL_NONE);

    // init
    tb_char_t const*    p = url;
    tb_size_t           protocol = TB_URL_PROTOCOL_NONE;
    if (!tb_strnicmp(p, "http://", 7))          protocol = TB_URL_PROTOCOL_HTTP;
    else if (!tb_strnicmp(p, "sock://", 7))     protocol = TB_URL_PROTOCOL_SOCK;
    else if (!tb_strnicmp(p, "file://", 7))     protocol = TB_URL_PROTOCOL_FILE;
    else if (!tb_strnicmp(p, "data://", 7))     protocol = TB_URL_PROTOCOL_DATA;
    else if (!tb_strnicmp(p, "https://", 8))    protocol = TB_URL_PROTOCOL_HTTP;
    else if (!tb_strnicmp(p, "socks://", 8))    protocol = TB_URL_PROTOCOL_SOCK;
    else if (!tb_strnicmp(p, "rtsp://", 7))     protocol = TB_URL_PROTOCOL_RTSP;
    else if (!tb_strnicmp(p, "sql://", 6))      protocol = TB_URL_PROTOCOL_SQL;
    else if (!tb_strnstr(p, 16, "://"))         protocol = TB_URL_PROTOCOL_FILE;
    else 
    {
        tb_trace_e("unknown protocol for url: %s", url);
    }

    // ok?
    return protocol;
}
tb_uint16_t tb_url_port(tb_url_ref_t url)
{
    // check
    tb_assert_and_check_return_val(url, 0);

    // get port
    return tb_ipaddr_port(&url->addr);
}
tb_void_t tb_url_port_set(tb_url_ref_t url, tb_uint16_t port)
{
    // check
    tb_assert_and_check_return(url);

    // set port
    tb_ipaddr_port_set(&url->addr, port);

    // clear url
    tb_string_clear(&url->cache);
}
tb_char_t const* tb_url_host(tb_url_ref_t url)
{
    // check
    tb_assert_and_check_return_val(url, tb_null);

    // get host
    return tb_string_size(&url->host)? tb_string_cstr(&url->host) : tb_null;
}
tb_void_t tb_url_host_set(tb_url_ref_t url, tb_char_t const* host)
{
    // check
    tb_assert_and_check_return(url);

    // clear cache
    tb_string_clear(&url->cache);

    // clear address
    tb_ipaddr_clear(&url->addr);

    // parse host
    tb_url_parse_host(&url->host, host);

    // attempt to parse address
    tb_ipaddr_ip_cstr_set(&url->addr, tb_string_cstr(&url->host), TB_IPADDR_FAMILY_NONE);
}
tb_ipaddr_ref_t tb_url_addr(tb_url_ref_t url)
{
    // check
    tb_assert_and_check_return_val(url, tb_null);

    // get address
    return &(url->addr);
}
tb_void_t tb_url_addr_set(tb_url_ref_t url, tb_ipaddr_ref_t addr)
{
    // check
    tb_assert_and_check_return(url && addr);

    // changed?
    if (!tb_ipaddr_is_equal(&url->addr, addr))
    {
        // set addr
        url->addr = *addr;

        // set it if the host not exists
        if (!tb_string_size(&url->host)) 
        {
            // address => host
            tb_char_t           data[TB_IPADDR_CSTR_MAXN];
            tb_char_t const*    host = tb_ipaddr_ip_cstr(addr, data, sizeof(data));
            if (host) tb_string_cstrcpy(&url->host, host);
 
            // clear url
            tb_string_clear(&url->cache);
        }
    }
}
tb_char_t const* tb_url_path(tb_url_ref_t url)
{
    // check
    tb_assert_and_check_return_val(url, tb_null);

    // get path
    return tb_string_size(&url->path)? tb_string_cstr(&url->path) : tb_null;
}
tb_void_t tb_url_path_set(tb_url_ref_t url, tb_char_t const* path)
{
    // check
    tb_assert_and_check_return(url);

    // clear cache
    tb_string_clear(&url->cache);

    // parse path
    tb_url_parse_path(&url->path, path);
}
tb_char_t const* tb_url_args(tb_url_ref_t url)
{
    // check
    tb_assert_and_check_return_val(url, tb_null);

    // get args
    return tb_string_size(&url->args)? tb_string_cstr(&url->args) : tb_null;
}
tb_void_t tb_url_args_set(tb_url_ref_t url, tb_char_t const* args)
{
    // check
    tb_assert_and_check_return(url);

    // clear cache
    tb_string_clear(&url->cache);

    // parse args
    tb_url_parse_args(&url->args, args);
}

