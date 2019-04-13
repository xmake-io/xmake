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
 * @file        sql.c
 * @defgroup    database
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "database"
#define TB_TRACE_MODULE_DEBUG           (1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "sql.h"
#include "impl/prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_database_sql_ref_t tb_database_sql_init(tb_char_t const* url)
{
    // check
    tb_assert_and_check_return_val(url, tb_null);

    // done
    tb_bool_t                   ok = tb_false;
    tb_database_sql_ref_t       database = tb_null;
    tb_url_t                    database_url;
    do
    {
        // trace
        tb_trace_d("init: %s: ..", url);

        // init url
        if (!tb_url_init(&database_url)) break;

        // make url
        if (!tb_url_cstr_set(&database_url, url)) break;

        // check protocol
        tb_size_t protocol = tb_url_protocol(&database_url);
        tb_assert_and_check_break(protocol == TB_URL_PROTOCOL_SQL || protocol == TB_URL_PROTOCOL_FILE);

        // the probe func
        static tb_size_t (*s_probe[])(tb_url_ref_t) = 
        {
            tb_null
#ifdef TB_CONFIG_PACKAGE_HAVE_MYSQL
        ,   tb_database_mysql_probe
#endif
#ifdef TB_CONFIG_PACKAGE_HAVE_SQLITE3
        ,   tb_database_sqlite3_probe
#endif
        };

        // the init func
        static tb_database_sql_ref_t (*s_init[])(tb_url_ref_t) = 
        {
            tb_null
#ifdef TB_CONFIG_PACKAGE_HAVE_MYSQL
        ,   tb_database_mysql_init
#endif
#ifdef TB_CONFIG_PACKAGE_HAVE_SQLITE3
        ,   tb_database_sqlite3_init
#endif
        };

        // probe the database type
        tb_size_t i = 1;
        tb_size_t n = tb_arrayn(s_probe);
        tb_size_t s = 0;
        tb_size_t m = 0;
        for (; i < n; i++)
        {
            if (s_probe[i]) 
            {
                // probe it
                tb_size_t score = s_probe[i](&database_url);
                if (score > s) 
                {
                    // save the max score
                    s = score;
                    m = i;

                    // ok?
                    if (score == 100) break;
                }
            }
        }
        tb_check_break(m < n && s_init[m]);

        // init it
        database = s_init[m](&database_url);
        tb_assert_and_check_break(database);

        // trace
        tb_trace_d("init: %s: ok", url);

        // ok
        ok = tb_true;

    } while (0);

    // exit url
    tb_url_exit(&database_url);

    // failed?
    if (!ok)
    {
        // trace
        tb_trace_d("init: %s: no", url);

        // exit database
        if (database) tb_database_sql_exit(database);
        database = tb_null;
    }

    // ok?
    return database;
}
tb_void_t tb_database_sql_exit(tb_database_sql_ref_t database)
{
    // check
    tb_database_sql_impl_t* impl = (tb_database_sql_impl_t*)database;
    tb_assert_and_check_return(impl);
        
    // trace
    tb_trace_d("exit: ..");

    // exit it
    if (impl->exit) impl->exit(impl);

    // trace
    tb_trace_d("exit: ok");
}
tb_size_t tb_database_sql_type(tb_database_sql_ref_t database)
{
    // check
    tb_database_sql_impl_t* impl = (tb_database_sql_impl_t*)database;
    tb_assert_and_check_return_val(impl, TB_DATABASE_SQL_TYPE_NONE);

    // the database type
    return impl->type;
}
tb_bool_t tb_database_sql_open(tb_database_sql_ref_t database)
{
    // check
    tb_database_sql_impl_t* impl = (tb_database_sql_impl_t*)database;
    tb_assert_and_check_return_val(impl && impl->open, tb_false);
    
    // opened?
    tb_check_return_val(!impl->bopened, tb_true);
    
    // init state
    impl->state = TB_STATE_DATABASE_UNKNOWN_ERROR;

    // open it
    impl->bopened = impl->open(impl);

    // save state
    if (impl->bopened) impl->state = TB_STATE_OK;

    // ok?
    return impl->bopened;
}
tb_void_t tb_database_sql_clos(tb_database_sql_ref_t database)
{
    // check
    tb_database_sql_impl_t* impl = (tb_database_sql_impl_t*)database;
    tb_assert_and_check_return(impl);
            
    // opened?
    tb_check_return(impl->bopened);

    // clos it
    if (impl->clos) impl->clos(impl);
    
    // closed
    impl->bopened = tb_false;
    
    // clear state
    impl->state = TB_STATE_OK;
}
tb_size_t tb_database_sql_state(tb_database_sql_ref_t database)
{
    // check
    tb_database_sql_impl_t* impl = (tb_database_sql_impl_t*)database;
    tb_assert_and_check_return_val(impl, TB_STATE_UNKNOWN_ERROR);
    
    // the state
    return impl->state;
}
tb_bool_t tb_database_sql_begin(tb_database_sql_ref_t database)
{
    // check
    tb_database_sql_impl_t* impl = (tb_database_sql_impl_t*)database;
    tb_assert_and_check_return_val(impl && impl->commit, tb_false);
    
    // init state
    impl->state = TB_STATE_DATABASE_UNKNOWN_ERROR;
        
    // opened?
    tb_assert_and_check_return_val(impl->bopened, tb_false);

    // begin it
    tb_bool_t ok = impl->begin(impl);

    // save state
    if (ok) impl->state = TB_STATE_OK;

    // ok?
    return ok;
}
tb_bool_t tb_database_sql_commit(tb_database_sql_ref_t database)
{
    // check
    tb_database_sql_impl_t* impl = (tb_database_sql_impl_t*)database;
    tb_assert_and_check_return_val(impl && impl->commit, tb_false);
    
    // init state
    impl->state = TB_STATE_DATABASE_UNKNOWN_ERROR;
        
    // opened?
    tb_assert_and_check_return_val(impl->bopened, tb_false);

    // commit it
    tb_bool_t ok = impl->commit(impl);

    // save state
    if (ok) impl->state = TB_STATE_OK;

    // ok?
    return ok;
}
tb_bool_t tb_database_sql_rollback(tb_database_sql_ref_t database)
{
    // check
    tb_database_sql_impl_t* impl = (tb_database_sql_impl_t*)database;
    tb_assert_and_check_return_val(impl && impl->rollback, tb_false);
    
    // init state
    impl->state = TB_STATE_DATABASE_UNKNOWN_ERROR;
        
    // opened?
    tb_assert_and_check_return_val(impl->bopened, tb_false);

    // rollback it
    tb_bool_t ok = impl->rollback(impl);

    // save state
    if (ok) impl->state = TB_STATE_OK;

    // ok?
    return ok;
}
tb_bool_t tb_database_sql_done(tb_database_sql_ref_t database, tb_char_t const* sql)
{
    // check
    tb_database_sql_impl_t* impl = (tb_database_sql_impl_t*)database;
    tb_assert_and_check_return_val(impl && impl->done && sql, tb_false);
    
    // init state
    impl->state = TB_STATE_DATABASE_UNKNOWN_ERROR;
        
    // opened?
    tb_assert_and_check_return_val(impl->bopened, tb_false);

    // done it
    tb_bool_t ok = impl->done(impl, sql);

    // trace
    tb_trace_d("done: sql: %s: %s", sql, ok? "ok" : "no");

    // save state
    if (ok) impl->state = TB_STATE_OK;

    // ok?
    return ok;
}
tb_iterator_ref_t tb_database_sql_result_load(tb_database_sql_ref_t database, tb_bool_t ball)
{
    // check
    tb_database_sql_impl_t* impl = (tb_database_sql_impl_t*)database;
    tb_assert_and_check_return_val(impl && impl->result_load, tb_null);
        
    // init state
    impl->state = TB_STATE_DATABASE_UNKNOWN_ERROR;

    // opened?
    tb_assert_and_check_return_val(impl->bopened, tb_null);

    // load it
    tb_iterator_ref_t result = impl->result_load(impl, ball);

    // save state
    if (result) impl->state = TB_STATE_OK;

    // ok?
    return result;
}
tb_void_t tb_database_sql_result_exit(tb_database_sql_ref_t database, tb_iterator_ref_t result)
{
    // check
    tb_database_sql_impl_t* impl = (tb_database_sql_impl_t*)database;
    tb_assert_and_check_return(impl && impl->result_exit && result);
            
    // opened?
    tb_assert_and_check_return(impl->bopened);

    // exit it
    impl->result_exit(impl, result);

    // clear state
    impl->state = TB_STATE_OK;
}
tb_database_sql_statement_ref_t tb_database_sql_statement_init(tb_database_sql_ref_t database, tb_char_t const* sql)
{
    // check
    tb_database_sql_impl_t* impl = (tb_database_sql_impl_t*)database;
    tb_assert_and_check_return_val(impl && impl->statement_init && sql, tb_null);
        
    // init state
    impl->state = TB_STATE_DATABASE_UNKNOWN_ERROR;

    // opened?
    tb_assert_and_check_return_val(impl->bopened, tb_null);

    // init statement
    tb_database_sql_statement_ref_t statement = impl->statement_init(impl, sql);
    
    // save state
    if (statement) impl->state = TB_STATE_OK;

    // ok?
    return statement;
}
tb_void_t tb_database_sql_statement_exit(tb_database_sql_ref_t database, tb_database_sql_statement_ref_t statement)
{
    // check
    tb_database_sql_impl_t* impl = (tb_database_sql_impl_t*)database;
    tb_assert_and_check_return(impl && impl->statement_done && statement);
    
    // opened?
    tb_assert_and_check_return(impl->bopened);

    // exit statement
    impl->statement_exit(impl, statement);

    // clear state
    impl->state = TB_STATE_OK;
}
tb_bool_t tb_database_sql_statement_done(tb_database_sql_ref_t database, tb_database_sql_statement_ref_t statement)
{
    // check
    tb_database_sql_impl_t* impl = (tb_database_sql_impl_t*)database;
    tb_assert_and_check_return_val(impl && impl->statement_done && statement, tb_false);
        
    // init state
    impl->state = TB_STATE_DATABASE_UNKNOWN_ERROR;

    // opened?
    tb_assert_and_check_return_val(impl->bopened, tb_false);

    // done statement
    tb_bool_t ok = impl->statement_done(impl, statement);

    // save state
    if (ok) impl->state = TB_STATE_OK;

    // ok?
    return ok;
}
tb_bool_t tb_database_sql_statement_bind(tb_database_sql_ref_t database, tb_database_sql_statement_ref_t statement, tb_database_sql_value_t const* list, tb_size_t size)
{
    // check
    tb_database_sql_impl_t* impl = (tb_database_sql_impl_t*)database;
    tb_assert_and_check_return_val(impl && impl->statement_bind && statement && list && size, tb_false);
        
    // init state
    impl->state = TB_STATE_DATABASE_UNKNOWN_ERROR;

    // opened?
    tb_assert_and_check_return_val(impl->bopened, tb_false);

    // bind statement argument
    tb_bool_t ok = impl->statement_bind(impl, statement, list, size);
    
    // save state
    if (ok) impl->state = TB_STATE_OK;

    // ok?
    return ok;
}
