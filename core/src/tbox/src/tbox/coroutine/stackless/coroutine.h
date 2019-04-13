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
 * @file        coroutine.h
 * @ingroup     coroutine
 *
 */
#ifndef TB_COROUTINE_STACKLESS_COROUTINE_H
#define TB_COROUTINE_STACKLESS_COROUTINE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "core.h"
#include "scheduler.h"
#include "../../libc/libc.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/// the self coroutine
#define tb_lo_coroutine_self()          (co__)

/* enter coroutine
 *
 * @code
 *
    // before
    tb_lo_coroutine_enter(co)
    {
        for (i = 0; i < 100; i++)
        {
            tb_lo_coroutine_yield();
        }
    }

    // after expanding again (init: branch = 0, state = TB_STATE_READY)
    tb_lo_coroutine_ref_t   co__ = co;
    tb_int_t                lo_yield_flag__ = 1; 
    for (; lo_yield_flag__; tb_lo_core(co__)->branch = 0, tb_lo_core(co__)->state = TB_STATE_END, lo_yield_flag__ = 0)
        switch (tb_lo_core(co__)->branch) 
            case 0:
                {
                    for (i = 0; i < 100; i++)
                    {
                        lo_yield_flag__ = 0;
                        tb_lo_core(co__)->branch = __tb_line__; case __tb_line__:;
                        if (lo_yield_flag__ == 0)
                            return ; 
                    }
                } 

    // or ..

    // after expanding again for gcc label (init: branch = tb_null, state = TB_STATE_READY)
    tb_lo_coroutine_ref_t   co__ = co;
    tb_int_t                lo_yield_flag__ = 1; 
    for (; lo_yield_flag__; tb_lo_core(co__)->branch = tb_null, tb_lo_core(co__)->state = TB_STATE_END, lo_yield_flag__ = 0)
        if (tb_lo_core(co)->branch) 
        { 
            goto *(tb_lo_core(co)->branch);
        } 
        else
        {
            for (i = 0; i < 100; i++)
            {
                lo_yield_flag__ = 0;
                do 
                { 
                    __tb_mconcat_ex__(__tb_lo_core_label, __tb_line__): 
                    tb_lo_core(co)->branch = &&__tb_mconcat_ex__(__tb_lo_core_label, __tb_line__); 
                    
                } while(0)

                if (lo_yield_flag__ == 0)
                    return ; 
            }
        }

 * @endcode
 */
#define tb_lo_coroutine_enter(co) \
    tb_lo_coroutine_ref_t   co__ = (co); \
    tb_int_t                lo_yield_flag__ = 1; \
    for ( ; lo_yield_flag__; tb_lo_core_exit(tb_lo_coroutine_self()), lo_yield_flag__ = 0) \
        tb_lo_core_resume(tb_lo_coroutine_self())

/// yield coroutine
#define tb_lo_coroutine_yield() \
do \
{ \
    lo_yield_flag__ = 0; \
    tb_lo_core_record(co__); \
    if (lo_yield_flag__ == 0) \
        return ; \
    \
} while(0)

/*! suspend current coroutine
 *
 * the scheduler will move this coroutine to the suspended coroutines after the function be returned
 *
 * @code
 *
    // before
    tb_lo_coroutine_enter(co)
    {
        for (i = 0; i < 100; i++)
        {
            tb_lo_coroutine_yield();
            tb_lo_coroutine_suspend();
        }
    }

    // after expanding again (init: branch = 0, state = TB_STATE_READY)
    tb_lo_coroutine_ref_t co__ = co;
    tb_int_t    lo_yield_flag__ = 1; 
    for (; lo_yield_flag__; tb_lo_core(co__)->branch = 0, tb_lo_core(co__)->state = TB_STATE_END, lo_yield_flag__ = 0)
        switch (tb_lo_core(co__)->branch) 
            case 0:
            {
                for (i = 0; i < 100; i++)
                {
                    lo_yield_flag__ = 0;
                    tb_lo_core(co__)->branch = __tb_line__; case __tb_line__:;
                    if (lo_yield_flag__ == 0)
                        return ; 

                    // suspend coroutine
                    tb_lo_core(co__)->state = TB_STATE_SUSPEND;
                    tb_lo_core(co__)->branch = __tb_line__; case __tb_line__:;
                    if (tb_lo_core(co__)->state == TB_STATE_SUSPEND)
                        return ; 
                }
            } 
 * @endcode
 */
#define tb_lo_coroutine_suspend() \
do \
{ \
    tb_used(&lo_yield_flag__); \
    tb_lo_core_state_set(tb_lo_coroutine_self(), TB_STATE_SUSPEND); \
    tb_lo_core_record(tb_lo_coroutine_self()); \
    if (tb_lo_core_state(tb_lo_coroutine_self()) == TB_STATE_SUSPEND) \
        return ; \
    \
} while(0)

/// sleep some time
#define tb_lo_coroutine_sleep(interval) \
do \
{ \
    if (interval) \
    { \
        tb_lo_coroutine_sleep_(tb_lo_coroutine_self(), interval); \
        tb_lo_coroutine_suspend(); \
    } \
    \
} while(0)

/// wait io socket events
#define tb_lo_coroutine_waitio(sock, events, interval) \
do \
{ \
    if (tb_lo_coroutine_waitio_(tb_lo_coroutine_self(), sock, events, interval)) \
    { \
        tb_lo_coroutine_suspend(); \
    } \
    \
} while(0)

/// wait until coroutine be true
#define tb_lo_coroutine_wait_until(cond) \
do \
{ \
    tb_used(&lo_yield_flag__); \
    tb_lo_core_record(tb_lo_coroutine_self()); \
    if (!(cond)) \
        return ; \
    \
} while(0)

/// wait while coroutine be true
#define tb_lo_coroutine_wait_while(pt, cond)    tb_lo_coroutine_wait_until(!(cond))

/// get socket events after waiting
#define tb_lo_coroutine_events()                tb_lo_coroutine_events_(tb_lo_coroutine_self())

/*! pass the user private data 
 *
 * @code
 
    // start coroutine 
    tb_lo_coroutine_start(scheduler, coroutine_func, tb_lo_coroutine_pass(tb_xxxx_priv_t));

 * @endcode
 *
 * =>
 *
 * @code
 
    // start coroutine
    tb_lo_coroutine_start(scheduler, coroutine_func, tb_malloc0_type(tb_xxxx_priv_t), tb_lo_coroutine_pass_free_);

 * @endcode
 */
#define tb_lo_coroutine_pass(type)  tb_malloc0_type(type), tb_lo_coroutine_pass_free_

/*! pass the user private data and init one member
 *
 * @code
 
    typedef struct __tb_xxxx_priv_t
    {
        tb_size_t   member;
        tb_size_t   others;

    }tb_xxxx_priv_t;
 
    // start coroutine 
    tb_lo_coroutine_start(scheduler, coroutine_func, tb_lo_coroutine_pass1(tb_xxxx_priv_t, member, value));

 * @endcode
 *
 * =>
 *
 * @code
 
    tb_xxxx_priv_t* priv = tb_malloc0_type(tb_xxxx_priv_t);
    if (priv)
    {
        priv->member = value;
    }
 
    // start coroutine
    tb_lo_coroutine_start(scheduler, coroutine_func, priv, tb_lo_coroutine_pass_free_);

 * @endcode
 */
#define tb_lo_coroutine_pass1(type, member, value)  tb_lo_coroutine_pass1_make_(sizeof(type), &(value), tb_offsetof(type, member), tb_memsizeof(type, member)), tb_lo_coroutine_pass_free_

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * private interfaces
 */

/* get the scheduler of coroutine
 *
 * @param coroutine     the coroutine 
 *
 * @return              the scheduler
 */
tb_lo_scheduler_ref_t   tb_lo_coroutine_scheduler_(tb_lo_coroutine_ref_t coroutine);

/* sleep the current coroutine
 *
 * @param coroutine     the coroutine 
 * @param interval      the interval (ms), infinity: -1
 */
tb_void_t               tb_lo_coroutine_sleep_(tb_lo_coroutine_ref_t coroutine, tb_long_t interval);

/* wait io events 
 *
 * @param coroutine     the coroutine 
 * @param sock          the socket
 * @param events        the waited events
 * @param timeout       the timeout, infinity: -1
 *
 * @return              suspend coroutine if be tb_true
 */
tb_bool_t               tb_lo_coroutine_waitio_(tb_lo_coroutine_ref_t coroutine, tb_socket_ref_t sock, tb_size_t events, tb_long_t timeout);

/* get the events after waiting socket
 *
 * @param coroutine     the coroutine 
 *
 * @return              events: > 0, failed: -1, timeout: 0
 */
tb_long_t               tb_lo_coroutine_events_(tb_lo_coroutine_ref_t coroutine);

/* free the user private data for pass()
 *
 * @note only be a wrapper of free() for tb_lo_coroutine_pass()
 *
 * @param priv          the user private data
 */
tb_void_t               tb_lo_coroutine_pass_free_(tb_cpointer_t priv);

/* make the user private data for pass1()
 *
 * @param type_size     the data type size
 * @param value         the value pointer
 * @param offset        the member offset
 * @param size          the value size
 *
 * @return              the user private data
 */
tb_pointer_t            tb_lo_coroutine_pass1_make_(tb_size_t type_size, tb_cpointer_t value, tb_size_t offset, tb_size_t size);

/* make the user private data for pass2()
 *
 * @param type_size     the data type size
 * @param value1        the value1 pointer
 * @param offset1       the member1 offset
 * @param size1         the value1 size
 * @param value2        the value2 pointer
 * @param offset2       the member2 offset
 * @param size2         the value2 size
 *
 * @return              the user private data
 */
tb_pointer_t            tb_lo_coroutine_pass2_make_(tb_size_t type_size, tb_cpointer_t value1, tb_size_t offset1, tb_size_t size1, tb_cpointer_t value2, tb_size_t offset2, tb_size_t size2);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! start coroutine 
 *
 * @code
    static tb_void_t switchtask(tb_lo_coroutine_ref_t coroutine, tb_cpointer_t priv)
    {
        // get count pointer (@note only allow non-status local variables)
        tb_size_t* count = (tb_size_t*)priv;

        // enter coroutine
        tb_lo_coroutine_enter(coroutine);

        // @note can not define local variables here
        // ...

        // loop
        while ((*count)--)
        {
            // yield
            tb_lo_coroutine_yield();
        }

        // leave coroutine
        tb_lo_coroutine_leave();
    }

    tb_int_t main (tb_int_t argc, tb_char_t** argv)
    {
        // init tbox
        if (!tb_init(tb_null, tb_null)) return -1;

        // init scheduler
        tb_lo_scheduler_ref_t scheduler = tb_lo_scheduler_init();
        if (scheduler)
        {
            // start coroutine
            tb_size_t counts[] = {100, 100};
            tb_lo_coroutine_start(scheduler, switchtask, &counts[0], tb_null);
            tb_lo_coroutine_start(scheduler, switchtask, &counts[1], tb_null);

            // run scheduler
            tb_lo_scheduler_loop(scheduler);

            // exit scheduler
            tb_lo_scheduler_exit(scheduler);
        }

        // exit tbox
        tb_exit();
    }

 * @endcode
 *
 * @param scheduler     the scheduler (can not be null, we can get scheduler of the current coroutine from tb_lo_scheduler_self())
 * @param func          the coroutine function
 * @param priv          the passed user private data as the argument of function
 * @param free          the user private free function
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_lo_coroutine_start(tb_lo_scheduler_ref_t scheduler, tb_lo_coroutine_func_t func, tb_cpointer_t priv, tb_lo_coroutine_free_t free);

/*! resume the given coroutine
 *
 * @param coroutine     the coroutine 
 */
tb_void_t               tb_lo_coroutine_resume(tb_lo_coroutine_ref_t coroutine);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
