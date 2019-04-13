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
 * @file        prefix.h
 *
 */
#ifndef TB_DATABASE_IMPL_PREFIX_H
#define TB_DATABASE_IMPL_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"
#include "../sql.h"
#include "sqlite3.h"
#include "mysql.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the database sql impl type
typedef struct __tb_database_sql_impl_t
{
    // the url
    tb_url_t                        url;

    // the type
    tb_size_t                       type;

    // the state
    tb_size_t                       state;

    // is opened?
    tb_bool_t                       bopened;

    // open
    tb_bool_t                       (*open)(struct __tb_database_sql_impl_t* database);

    // clos
    tb_void_t                       (*clos)(struct __tb_database_sql_impl_t* database);

    // exit
    tb_void_t                       (*exit)(struct __tb_database_sql_impl_t* database);

    // done
    tb_bool_t                       (*done)(struct __tb_database_sql_impl_t* database, tb_char_t const* sql);

    // begin
    tb_bool_t                       (*begin)(struct __tb_database_sql_impl_t* database);

    // commit
    tb_bool_t                       (*commit)(struct __tb_database_sql_impl_t* database);

    // rollback
    tb_bool_t                       (*rollback)(struct __tb_database_sql_impl_t* database);

    // load result
    tb_iterator_ref_t               (*result_load)(struct __tb_database_sql_impl_t* database, tb_bool_t try_all);

    // exit result
    tb_void_t                       (*result_exit)(struct __tb_database_sql_impl_t* database, tb_iterator_ref_t result);

    // statement init
    tb_database_sql_statement_ref_t (*statement_init)(struct __tb_database_sql_impl_t* database, tb_char_t const* sql);

    // statement exit
    tb_void_t                       (*statement_exit)(struct __tb_database_sql_impl_t* database, tb_database_sql_statement_ref_t statement);

    // statement done
    tb_bool_t                       (*statement_done)(struct __tb_database_sql_impl_t* database, tb_database_sql_statement_ref_t statement);

    // statement bind
    tb_bool_t                       (*statement_bind)(struct __tb_database_sql_impl_t* database, tb_database_sql_statement_ref_t statement, tb_database_sql_value_t const* list, tb_size_t size);

}tb_database_sql_impl_t;


#endif
