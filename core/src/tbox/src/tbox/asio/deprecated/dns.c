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
 * Copyright (C) 2009 - 2017, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        dns.c
 * @ingroup     asio
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "aicp_dns"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "dns.h"
#include "aico.h"
#include "aicp.h"
#include "../../network/network.h"
#include "../../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the aicp impl done type
typedef struct __tb_aicp_dns_done_t
{
    // the func
    tb_aicp_dns_done_func_t func;

    // the priv
    tb_cpointer_t           priv;

}tb_aicp_dns_done_t;

// the aicp impl type
typedef struct __tb_aicp_dns_impl_t
{
    // the done 
    tb_aicp_dns_done_t      done;

    // the aicp
    tb_aicp_ref_t           aicp;

    // the aico
    tb_aico_ref_t           aico;

    // the server indx
    tb_size_t               indx;

    // the server list
    tb_ipaddr_t             list[3];

    // the server size
    tb_size_t               size;

    // the data
    tb_byte_t               data[TB_DNS_RPKT_MAXN];

    // the host
    tb_char_t               host[256];

}tb_aicp_dns_impl_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_size_t tb_aicp_dns_reqt_init(tb_aicp_dns_impl_t* impl)
{
    // check
    tb_assert_and_check_return_val(impl, 0);

    // init query data
    tb_static_stream_t stream;
    tb_static_stream_init(&stream, impl->data, TB_DNS_RPKT_MAXN);

    // identification number
    tb_static_stream_writ_u16_be(&stream, TB_DNS_HEADER_MAGIC);

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
    tb_static_stream_writ_u16_be(&stream, 0x0100);
#else
    tb_static_stream_writ_u1(&stream, 0);          // this is a query
    tb_static_stream_writ_ubits32(&stream, 0, 4);  // this is a standard query
    tb_static_stream_writ_u1(&stream, 0);          // not authoritive answer
    tb_static_stream_writ_u1(&stream, 0);          // not truncated
    tb_static_stream_writ_u1(&stream, 1);          // recursion desired

    tb_static_stream_writ_u1(&stream, 0);          // recursion not available! hey we dont have it (lol)
    tb_static_stream_writ_u1(&stream, 0);
    tb_static_stream_writ_u1(&stream, 0);
    tb_static_stream_writ_u1(&stream, 0);
    tb_static_stream_writ_ubits32(&stream, 0, 4);
#endif

    /* we have only one question
     *
     * tb_uint16_t question;        // number of question entries
     * tb_uint16_t answer;          // number of answer entries
     * tb_uint16_t authority;       // number of authority entries
     * tb_uint16_t resource;        // number of resource entries
     *
     */
    tb_static_stream_writ_u16_be(&stream, 1); 
    tb_static_stream_writ_u16_be(&stream, 0);
    tb_static_stream_writ_u16_be(&stream, 0);
    tb_static_stream_writ_u16_be(&stream, 0);

    // set questions, see as tb_dns_question_t
    // name + question1 + question2 + ...
    tb_static_stream_writ_u8(&stream, '.');
    tb_char_t* p = tb_static_stream_writ_cstr(&stream, impl->host);

    // only one question now.
    tb_static_stream_writ_u16_be(&stream, 1);      // we are requesting the ipv4 dnsess
    tb_static_stream_writ_u16_be(&stream, 1);      // it's internet (lol)

    // encode impl name
    if (!p || !tb_dns_encode_name(p - 1)) return 0;

    // ok?
    return tb_static_stream_offset(&stream);
}
static tb_bool_t tb_aicp_dns_resp_done(tb_aicp_dns_impl_t* impl, tb_size_t size, tb_ipaddr_ref_t addr)
{
    // check
    tb_assert_and_check_return_val(impl && addr, tb_false);

    // check
    tb_assert_and_check_return_val(size >= TB_DNS_HEADER_SIZE, tb_false);

    // init stream
    tb_static_stream_t stream;
    tb_static_stream_init(&stream, impl->data, size);
    
    // init header
    tb_dns_header_t header;
    header.id           = tb_static_stream_read_u16_be(&stream); tb_static_stream_skip(&stream, 2);
    header.question     = tb_static_stream_read_u16_be(&stream);
    header.answer       = tb_static_stream_read_u16_be(&stream);
    header.authority    = tb_static_stream_read_u16_be(&stream);
    header.resource     = tb_static_stream_read_u16_be(&stream);

    // trace
    tb_trace_d("response: size: %u",        size);
    tb_trace_d("response: id: 0x%04x",      header.id);
    tb_trace_d("response: question: %d",    header.question);
    tb_trace_d("response: answer: %d",      header.answer);
    tb_trace_d("response: authority: %d",   header.authority);
    tb_trace_d("response: resource: %d",    header.resource);
    tb_trace_d("");

    // check header
    tb_assert_and_check_return_val(header.id == TB_DNS_HEADER_MAGIC, tb_false);

    // skip questions, only one question now.
    // name + question1 + question2 + ...
    tb_assert_and_check_return_val(header.question == 1, tb_false);
#if 1
    tb_static_stream_skip_cstr(&stream);
    tb_static_stream_skip(&stream, 4);
#else
    tb_char_t* name = tb_static_stream_read_cstr(&stream);
    //name = tb_dns_decode_name(name);
    tb_assert_and_check_return_val(name, tb_false);
    tb_static_stream_skip(&stream, 4);
    tb_trace_d("response: name: %s", name);
#endif

    // decode answers
    tb_size_t i = 0;
    tb_size_t found = 0;
    for (i = 0; i < header.answer; i++)
    {
        // decode answer
        tb_dns_answer_t answer;

        // trace
        tb_trace_d("response: answer: %d", i);

        // decode impl name
        tb_char_t const* name = tb_dns_decode_name(&stream, answer.name); tb_used(name);

        // trace
        tb_trace_d("response: name: %s", name);

        // decode resource
        answer.res.type     = tb_static_stream_read_u16_be(&stream);
        answer.res.class_   = tb_static_stream_read_u16_be(&stream);
        answer.res.ttl      = tb_static_stream_read_u32_be(&stream);
        answer.res.size     = tb_static_stream_read_u16_be(&stream);

        // trace
        tb_trace_d("response: type: %d",    answer.res.type);
        tb_trace_d("response: class: %d",   answer.res.class_);
        tb_trace_d("response: ttl: %d",     answer.res.ttl);
        tb_trace_d("response: size: %d",    answer.res.size);

        // is ipv4?
        if (answer.res.type == 1)
        {
            // get ipv4
            tb_byte_t b1 = tb_static_stream_read_u8(&stream);
            tb_byte_t b2 = tb_static_stream_read_u8(&stream);
            tb_byte_t b3 = tb_static_stream_read_u8(&stream);
            tb_byte_t b4 = tb_static_stream_read_u8(&stream);

            // trace
            tb_trace_d("response: ipv4: %u.%u.%u.%u", b1, b2, b3, b4);

            // save the first ip
            if (!found) 
            {
                // save it
                if (addr)
                {
                    // init ipv4
                    tb_ipv4_t ipv4;
                    ipv4.u8[0] = b1;
                    ipv4.u8[1] = b2;
                    ipv4.u8[2] = b3;
                    ipv4.u8[3] = b4;

                    // save ipv4
                    tb_ipaddr_ipv4_set(addr, &ipv4);
                }

                // found it
                found = 1;

                // trace
                tb_trace_d("response: ");
                break;
            }
        }
        else
        {
            // decode rdata
            answer.rdata = (tb_byte_t const*)tb_dns_decode_name(&stream, answer.name);

            // trace
            tb_trace_d("response: alias: %s", answer.rdata? (tb_char_t const*)answer.rdata : "");
        }

        // trace
        tb_trace_d("response: ");
    }

    // found it?
    tb_check_return_val(found, tb_false);

    // ok
    return tb_true;
}
static tb_bool_t tb_aicp_dns_reqt_func(tb_aice_ref_t aice);
static tb_bool_t tb_aicp_dns_resp_func(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && aice->aico && aice->code == TB_AICE_CODE_URECV, tb_false);

    // the aicp
    tb_aicp_ref_t aicp = (tb_aicp_ref_t)tb_aico_aicp(aice->aico);
    tb_assert_and_check_return_val(aicp, tb_false);
    
    // the impl
    tb_aicp_dns_impl_t* impl = (tb_aicp_dns_impl_t*)aice->priv; 
    tb_assert_and_check_return_val(impl, tb_false);

    // done
    tb_ipaddr_t addr = {0};
    if (aice->state == TB_STATE_OK)
    {
        // trace
        tb_trace_d("resp[%s]: aico: %p, server: %{ipaddr}, real: %lu", impl->host, impl->aico, &aice->u.urecv.addr, aice->u.urecv.real);

        // check
        tb_assert_and_check_return_val(aice->u.urecv.real, tb_false);

        // done resp
        tb_aicp_dns_resp_done(impl, aice->u.urecv.real, &addr);
    }
    // timeout or failed?
    else
    {
        // trace
        tb_trace_d("resp[%s]: aico: %p, state: %s", impl->host, impl->aico, tb_state_cstr(aice->state));
    }

    // ok or try to get ok from cache again if failed or timeout? 
    tb_bool_t from_cache = tb_false;
    if (!tb_ipaddr_ip_is_empty(&addr) || (from_cache = tb_dns_cache_get(impl->host, &addr))) 
    {
        // save to cache 
        if (!from_cache) tb_dns_cache_set(impl->host, &addr);
        
        // done func
        impl->done.func((tb_aicp_dns_ref_t)impl, impl->host, &addr, impl->done.priv);
        return tb_true;
    }

    // try next server?
    tb_bool_t           ok = tb_false;
    tb_ipaddr_ref_t     server = &impl->list[impl->indx + 1];
    if (!tb_ipaddr_is_empty(server))
    {   
        // indx++
        impl->indx++;

        // init reqt
        tb_size_t size = tb_aicp_dns_reqt_init(impl);
        if (size)
        {
            // post reqt
            ok = tb_aico_usend(aice->aico, server, impl->data, size, tb_aicp_dns_reqt_func, (tb_pointer_t)impl);
        }
    }

    // failed? done func
    if (!ok) impl->done.func((tb_aicp_dns_ref_t)impl, impl->host, tb_null, impl->done.priv);

    // continue
    return tb_true;
}
static tb_bool_t tb_aicp_dns_reqt_func(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && aice->aico && aice->code == TB_AICE_CODE_USEND, tb_false);

    // the aicp
    tb_aicp_ref_t aicp = (tb_aicp_ref_t)tb_aico_aicp(aice->aico);
    tb_assert_and_check_return_val(aicp, tb_false);
    
    // the impl
    tb_aicp_dns_impl_t* impl = (tb_aicp_dns_impl_t*)aice->priv; 
    tb_assert_and_check_return_val(impl && impl->done.func, tb_false);

    // done
    tb_bool_t ok = tb_false;
    if (aice->state == TB_STATE_OK)
    {
        // trace
        tb_trace_d("reqt[%s]: aico: %p, server: %{ipaddr}, real: %lu", impl->host, impl->aico, &aice->u.usend.addr, aice->u.usend.real);

        // check
        tb_assert_and_check_return_val(aice->u.usend.real, tb_false);

        // post resp
        ok = tb_aico_urecv(aice->aico, impl->data, sizeof(impl->data), tb_aicp_dns_resp_func, (tb_pointer_t)impl);
    }
    // timeout or failed?
    else
    {
        // trace
        tb_trace_d("reqt[%s]: aico: %p, server: %{ipaddr}, state: %s", impl->host, impl->aico, &aice->u.usend.addr, tb_state_cstr(aice->state));
            
        // the next server 
        tb_ipaddr_ref_t server = &impl->list[impl->indx + 1];
        if (!tb_ipaddr_is_empty(server))
        {   
            // indx++
            impl->indx++;

            // init reqt
            tb_size_t size = tb_aicp_dns_reqt_init(impl);
            if (size)
            {
                // post reqt
                ok = tb_aico_usend(aice->aico, server, impl->data, size, tb_aicp_dns_reqt_func, (tb_pointer_t)impl);
            }
        }
    }

    // failed? done func
    if (!ok) impl->done.func((tb_aicp_dns_ref_t)impl, impl->host, tb_null, impl->done.priv);

    // continue 
    return tb_true;
}
static tb_bool_t tb_aicp_dns_clos_func(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && aice->aico && aice->code == TB_AICE_CODE_CLOS, tb_false);

    // trace
    tb_trace_d("exit: aico: %p: ok", aice->aico);

    // exit aico
    tb_aico_exit(aice->aico);

    // ok
    return tb_true;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_aicp_dns_ref_t tb_aicp_dns_init(tb_aicp_ref_t aicp)
{
    // check
    tb_assert_and_check_return_val(aicp, tb_null);

    // done
    tb_bool_t               ok = tb_false;
    tb_aicp_dns_impl_t*     impl = tb_null;
    do
    {
        // make impl
        impl = tb_malloc0_type(tb_aicp_dns_impl_t);
        tb_assert_and_check_break(impl);

        // init aicp
        impl->aicp = aicp;

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (impl) tb_aicp_dns_exit((tb_aicp_dns_ref_t)impl);
        impl = tb_null;
    }

    // ok?
    return (tb_aicp_dns_ref_t)impl;
}
tb_void_t tb_aicp_dns_kill(tb_aicp_dns_ref_t dns)
{
    // check
    tb_aicp_dns_impl_t* impl = (tb_aicp_dns_impl_t*)dns;
    tb_assert_and_check_return(impl);

    // trace
    tb_trace_d("kill: aico: %p ..", impl->aico);

    // kill it
    if (impl->aico) tb_aico_kill(impl->aico);
}
tb_void_t tb_aicp_dns_exit(tb_aicp_dns_ref_t dns)
{
    // check
    tb_aicp_dns_impl_t* impl = (tb_aicp_dns_impl_t*)dns;
    tb_assert_and_check_return(impl);

    // trace
    tb_trace_d("exit: aico: %p ..", impl->aico);

    // clos aico
    if (impl->aico) tb_aico_clos(impl->aico, tb_aicp_dns_clos_func, tb_null);
    impl->aico = tb_null;

    // exit it
    tb_free(impl);
}
tb_bool_t tb_aicp_dns_done(tb_aicp_dns_ref_t dns, tb_char_t const* host, tb_long_t timeout, tb_aicp_dns_done_func_t func, tb_cpointer_t priv)
{
    // check
    tb_aicp_dns_impl_t* impl = (tb_aicp_dns_impl_t*)dns;
    tb_assert_and_check_return_val(impl && func && host && host[0], tb_false);
    
    // trace
    tb_trace_d("done: aico: %p, host: %s: ..", impl->aico, host);

    // init func
    impl->done.func = func;
    impl->done.priv = priv;

    // save host
    tb_strlcpy(impl->host, host, sizeof(impl->host));
 
    // only address? ok
    tb_ipaddr_t addr = {0};
    if (tb_ipaddr_ip_cstr_set(&addr, impl->host, TB_IPADDR_FAMILY_NONE))
    {
        impl->done.func(dns, impl->host, &addr, impl->done.priv);
        return tb_true;
    }

    // try to lookup it from cache first
    if (tb_dns_cache_get(impl->host, &addr))
    {
        impl->done.func(dns, impl->host, &addr, impl->done.priv);
        return tb_true;
    }

    // init server list
    if (!impl->size) impl->size = tb_dns_server_get(impl->list);
    tb_check_return_val(impl->size, tb_false);

    // get the server 
    tb_ipaddr_ref_t server = &impl->list[impl->indx = 0];
    tb_assert_and_check_return_val(!tb_ipaddr_is_empty(server), tb_false);

    // init reqt
    tb_size_t size = tb_aicp_dns_reqt_init(impl);
    tb_assert_and_check_return_val(size, tb_false);

    // init it first if no aico
    if (!impl->aico)
    {
        // init aico
        impl->aico = tb_aico_init(impl->aicp);
        tb_assert_and_check_return_val(impl->aico, tb_false);

        // open aico
        if (!tb_aico_open_sock_from_type(impl->aico, TB_SOCKET_TYPE_UDP, tb_ipaddr_family(server))) return tb_false;

        // init timeout
        tb_aico_timeout_set(impl->aico, TB_AICO_TIMEOUT_SEND, timeout);
        tb_aico_timeout_set(impl->aico, TB_AICO_TIMEOUT_RECV, timeout);
    }

    // post reqt
    return tb_aico_usend(impl->aico, server, impl->data, size, tb_aicp_dns_reqt_func, (tb_pointer_t)impl);
}
tb_aicp_ref_t tb_aicp_dns_aicp(tb_aicp_dns_ref_t dns)
{
    // check
    tb_aicp_dns_impl_t* impl = (tb_aicp_dns_impl_t*)dns;
    tb_assert_and_check_return_val(impl && impl->aico, tb_null);
    
    // the aicp
    return impl->aicp;
}
