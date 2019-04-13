/*!The Treasure Box Library
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
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
 * @file        server.c
 * @ingroup     network
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME        "dns_server"
#define TB_TRACE_MODULE_DEBUG       (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "server.h"
#include "../../utils/utils.h"
#include "../../stream/stream.h"
#include "../../network/network.h"
#include "../../platform/platform.h"
#include "../../container/container.h"
#include "../../algorithm/algorithm.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the dns server test timeout
#define TB_DNS_SERVER_TEST_TIMEOUT  (500)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the dns server type
typedef struct __tb_dns_server_t
{
    // the rate
    tb_size_t               rate;

    // the addr
    tb_ipaddr_t             addr;

}tb_dns_server_t, *tb_dns_server_ref_t;

// the dns server list type
typedef struct __tb_dns_server_list_t
{
    // is sorted?
    tb_bool_t               sort;

    // the server list
    tb_vector_ref_t         list;

}tb_dns_server_list_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// the lock
static tb_spinlock_t        g_lock = TB_SPINLOCK_INIT;

// the server list
static tb_dns_server_list_t g_list = {0};

/* //////////////////////////////////////////////////////////////////////////////////////
 * server
 */
static tb_long_t tb_dns_server_comp(tb_element_ref_t element, tb_cpointer_t litem, tb_cpointer_t ritem)
{
    // check
    tb_assert(litem && ritem);

    // the rate
    tb_size_t lrate = ((tb_dns_server_t const*)litem)->rate;
    tb_size_t rrate = ((tb_dns_server_t const*)ritem)->rate;

    // comp
    return (lrate > rrate? 1 : (lrate < rrate? -1 : 0));
}
static tb_long_t tb_dns_server_test(tb_ipaddr_ref_t addr)
{
    // check
    tb_assert_and_check_return_val(addr && !tb_ipaddr_is_empty(addr), -1);

    // done
    tb_static_stream_t  sstream;
    tb_byte_t           rpkt[TB_DNS_RPKT_MAXN];
    tb_size_t           size = 0;
    tb_long_t           rate = -1;
    tb_socket_ref_t     sock = tb_null;
    do
    { 
        // trace
        tb_trace_d("test: %{ipaddr}: ..", addr);

        // init sock
        sock = tb_socket_init(TB_SOCKET_TYPE_UDP, tb_ipaddr_family(addr));
        tb_assert_and_check_break(sock);

        // init stream
        tb_static_stream_init(&sstream, rpkt, TB_DNS_RPKT_MAXN);

        // identification number
        tb_static_stream_writ_u16_be(&sstream, TB_DNS_HEADER_MAGIC);

        /* 0x2104: 0 0000 001 0000 0000
         *
         * tb_uint16_t qr     :1;       // query/response flag
         * tb_uint16_t opcode :4;       // purpose of message
         * tb_uint16_t aa     :1;       // authoritive answer
         * tb_uint16_t tc     :1;       // truncated message
         * tb_uint16_t rd     :1;       // recursion desired

         * tb_uint16_t ra     :1;       // recursion available
         * tb_uint16_t z      :1;       // its z! reserved
         * tb_uint16_t ad     :1;       // authenticated data
         * tb_uint16_t cd     :1;       // checking disabled
         * tb_uint16_t rcode  :4;       // response code
         *
         * this is a query 
         * this is a standard query 
         * not authoritive answer 
         * not truncated 
         * recursion desired
         *
         * recursion not available! hey we dont have it (lol)
         *
         */
#if 1
        tb_static_stream_writ_u16_be(&sstream, 0x0100);
#else
        tb_static_stream_writ_u1(&sstream, 0);          // this is a query
        tb_static_stream_writ_ubits32(&sstream, 0, 4);  // this is a standard query
        tb_static_stream_writ_u1(&sstream, 0);          // not authoritive answer
        tb_static_stream_writ_u1(&sstream, 0);          // not truncated
        tb_static_stream_writ_u1(&sstream, 1);          // recursion desired

        tb_static_stream_writ_u1(&sstream, 0);          // recursion not available! hey we dont have it (lol)
        tb_static_stream_writ_u1(&sstream, 0);
        tb_static_stream_writ_u1(&sstream, 0);
        tb_static_stream_writ_u1(&sstream, 0);
        tb_static_stream_writ_ubits32(&sstream, 0, 4);
#endif

        /* we have only one question
         *
         * tb_uint16_t question;        // number of question entries
         * tb_uint16_t answer;          // number of answer entries
         * tb_uint16_t authority;       // number of authority entries
         * tb_uint16_t resource;        // number of resource entries
         *
         */
        tb_static_stream_writ_u16_be(&sstream, 1); 
        tb_static_stream_writ_u16_be(&sstream, 0);
        tb_static_stream_writ_u16_be(&sstream, 0);
        tb_static_stream_writ_u16_be(&sstream, 0);

        // set questions, see as tb_dns_question_t
        // name + question1 + question2 + ...
        tb_static_stream_writ_u8(&sstream, 3);
        tb_static_stream_writ_u8(&sstream, 'w');
        tb_static_stream_writ_u8(&sstream, 'w');
        tb_static_stream_writ_u8(&sstream, 'w');
        tb_static_stream_writ_u8(&sstream, 5);
        tb_static_stream_writ_u8(&sstream, 't');
        tb_static_stream_writ_u8(&sstream, 'b');
        tb_static_stream_writ_u8(&sstream, 'o');
        tb_static_stream_writ_u8(&sstream, 'o');
        tb_static_stream_writ_u8(&sstream, 'x');
        tb_static_stream_writ_u8(&sstream, 3);
        tb_static_stream_writ_u8(&sstream, 'o');
        tb_static_stream_writ_u8(&sstream, 'r');
        tb_static_stream_writ_u8(&sstream, 'g');
        tb_static_stream_writ_u8(&sstream, '\0');

        // only one question now.
        tb_static_stream_writ_u16_be(&sstream, 1);      // we are requesting the ipv4 address
        tb_static_stream_writ_u16_be(&sstream, 1);      // it's internet (lol)

        // size
        size = tb_static_stream_offset(&sstream);
        tb_assert_and_check_break(size);

        // init time
        tb_hong_t time = tb_cache_time_spak();

        // se/nd request
        tb_size_t writ = 0;
        tb_bool_t fail = tb_false;
        while (writ < size)
        {
            // writ data
            tb_long_t real = tb_socket_usend(sock, addr, rpkt + writ, size - writ);

            // trace
            tb_trace_d("writ %ld", real);

            // check
            tb_check_break_state(real >= 0, fail, tb_true);
            
            // no data?
            if (!real)
            {
                // abort?
                tb_check_break_state(!writ, fail, tb_true);
     
                // wait
                real = tb_socket_wait(sock, TB_SOCKET_EVENT_SEND, TB_DNS_SERVER_TEST_TIMEOUT);

                // fail or timeout?
                tb_check_break_state(real > 0, fail, tb_true);
            }
            else writ += real;
        }

        // failed?
        tb_check_break(!fail);

        // only recv id & answer, 8 bytes 
        tb_long_t read = 0;
        while (read < 8)
        {
            // read data
            tb_long_t r = tb_socket_urecv(sock, tb_null, rpkt + read, TB_DNS_RPKT_MAXN - read);

            // trace
            tb_trace_d("read %ld", r);

            // check
            tb_check_break(r >= 0);
            
            // no data?
            if (!r)
            {
                // end?
                tb_check_break(!read);

                // wait
                r = tb_socket_wait(sock, TB_SOCKET_EVENT_RECV, TB_DNS_SERVER_TEST_TIMEOUT);

                // trace
                tb_trace_d("wait %ld", r);

                // fail or timeout?
                tb_check_break(r > 0);
            }
            else read += r;
        }

        // check
        tb_check_break(read >= 8);

        // check protocol
        tb_size_t id = tb_bits_get_u16_be(rpkt);
        tb_check_break(id == TB_DNS_HEADER_MAGIC);

        // check answer
        tb_size_t answer = tb_bits_get_u16_be(rpkt + 6);
        tb_check_break(answer > 0);

        // rate
        rate = (tb_long_t)(tb_cache_time_spak() - time);

        // ok
        tb_trace_d("test: %{ipaddr} ok, rate: %u", addr, rate);

    } while (0);

    // exit sock
    tb_socket_exit(sock);

    // ok
    return rate;
}
static tb_bool_t tb_dns_server_rate(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t value)
{
    // the server
    tb_bool_t               ok = tb_false;
    tb_dns_server_ref_t     server = (tb_dns_server_ref_t)item;
    if (server && !server->rate)
    {
        // done
        tb_bool_t done = tb_false;
        do
        {
            // the server rate
            tb_long_t rate = tb_dns_server_test(&server->addr);
            tb_check_break(rate >= 0);

            // save the server rate
            server->rate = rate;

            // ok
            done = tb_true;

        } while (0);

        // failed? remove it
        if (!done) ok = tb_true;
    }

    // ok?
    return ok;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

tb_bool_t tb_dns_server_init()
{
    // enter
    tb_spinlock_enter(&g_lock);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // init list
        if (!g_list.list) 
        {
            g_list.list = tb_vector_init(8, tb_element_mem(sizeof(tb_dns_server_t), tb_null, tb_null));
            g_list.sort = tb_false;
        }
        tb_assert_and_check_break(g_list.list);

        // ok
        ok = tb_true;

    } while (0);

    // leave
    tb_spinlock_leave(&g_lock);

    // failed? exit it
    if (!ok) tb_dns_server_exit();

    // ok?
    return ok;
}
tb_void_t tb_dns_server_exit()
{
    // enter
    tb_spinlock_enter(&g_lock);

    // exit list
    if (g_list.list) tb_vector_exit(g_list.list);
    g_list.list = tb_null;

    // exit sort
    g_list.sort = tb_false;

    // leave
    tb_spinlock_leave(&g_lock);
}
tb_void_t tb_dns_server_dump()
{
    // enter
    tb_spinlock_enter(&g_lock);
    
    // dump list
    if (g_list.list) 
    {
        // trace
        tb_trace_i("============================================================");
        tb_trace_i("list: %u servers", tb_vector_size(g_list.list));

        // walk
        tb_size_t i = 0;
        tb_size_t n = tb_vector_size(g_list.list);
        for (; i < n; i++)
        {
            tb_dns_server_t const* server = (tb_dns_server_t const*)tb_iterator_item(g_list.list, i);
            if (server)
            {
                // trace
                tb_trace_i("server: %{ipaddr}, rate: %u", &server->addr, server->rate);
            }
        }
    }

    // leave
    tb_spinlock_leave(&g_lock);
}
tb_void_t tb_dns_server_sort()
{
    // enter
    tb_spinlock_enter(&g_lock);

    // done
    tb_vector_ref_t list = tb_null;
    do
    {
        // check
        tb_assert_and_check_break(g_list.list);

        // need sort?
        tb_check_break(!g_list.sort);

        // init element
        tb_element_t element = tb_element_mem(sizeof(tb_dns_server_t), tb_null, tb_null);
        element.comp = tb_dns_server_comp;

        // init list
        list = tb_vector_init(8, element);
        tb_assert_and_check_break(list);
        
        // copy list
        tb_vector_copy(list, g_list.list);

    } while (0);

    /* sort ok, only done once sort
     * using the unsorted server list at the other thread if the sort have been not finished
     */
    g_list.sort = tb_true;

    // leave
    tb_spinlock_leave(&g_lock);

    // need sort?
    tb_check_return(list);

    // rate list and remove no-rate servers
    tb_remove_if(list, tb_dns_server_rate, tb_null);

    // sort list
    tb_sort_all(list, tb_null);
    
    // enter
    tb_spinlock_enter(&g_lock);

    // save the sorted server list
    if (tb_vector_size(list)) tb_vector_copy(g_list.list, list);
    else
    {
        // no faster server? using the previous server list
        tb_trace_w("no faster server");
    }

    // leave
    tb_spinlock_leave(&g_lock);

    // exit list
    tb_vector_exit(list);
}
tb_size_t tb_dns_server_get(tb_ipaddr_t addr[2])
{ 
    // check
    tb_assert_and_check_return_val(addr, 0);

    // sort first
    tb_dns_server_sort();
        
    // enter
    tb_spinlock_enter(&g_lock);

    // done
    tb_size_t ok = 0;
    do
    {
        // check
        tb_assert_and_check_break(g_list.list && g_list.sort);

        // init
        tb_size_t i = 0;
        tb_size_t n = tb_min(tb_vector_size(g_list.list), 2);
        tb_assert_and_check_break(n <= 2);

        // done
        for (; i < n; i++)
        {
            // the dns server
            tb_dns_server_t const* server = (tb_dns_server_t const*)tb_iterator_item(g_list.list, i);
            if (server) 
            {
                // save addr
                addr[ok++] = server->addr;
            }
        }

    } while (0);

    // leave
    tb_spinlock_leave(&g_lock);

    // trace
    tb_assertf(ok, "no server!");

    // ok?
    return ok;
}
tb_void_t tb_dns_server_add(tb_char_t const* addr)
{
    // check
    tb_assert_and_check_return(addr);

    // init first
    tb_dns_server_init();

    // enter
    tb_spinlock_enter(&g_lock);

    // done
    do
    {
        // check
        tb_assert_and_check_break(g_list.list);

        // init server
        tb_dns_server_t server = {0};
        if (!tb_ipaddr_set(&server.addr, addr, TB_DNS_HOST_PORT, TB_IPADDR_FAMILY_NONE)) break;

        // add server
        tb_vector_insert_tail(g_list.list, &server);

        // need sort it again
        g_list.sort = tb_false;

    } while (0);

    // leave
    tb_spinlock_leave(&g_lock);
}

