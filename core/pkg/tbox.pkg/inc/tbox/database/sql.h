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
 * @file        sql.h
 * @defgroup    database
 */
#ifndef TB_DATABASE_SQL_H
#define TB_DATABASE_SQL_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "value.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the sql database type enum
typedef enum __tb_database_sql_type_e
{
    TB_DATABASE_SQL_TYPE_NONE               = 0
,   TB_DATABASE_SQL_TYPE_MYSQL              = 1
,   TB_DATABASE_SQL_TYPE_SQLITE3            = 2

}tb_database_sql_type_e;

/// the database sql ref type
typedef struct{}*       tb_database_sql_ref_t;

/// the database sql statement ref type
typedef struct{}*       tb_database_sql_statement_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init sql database
 *
 * @param url                       the database url
 *                                  "sql://localhost/?type=mysql&username=xxxx&password=xxxx"
 *                                  "sql://localhost:3306/?type=mysql&username=xxxx&password=xxxx&database=xxxx"
 *                                  "sql:///home/file.sqlitedb?type=sqlite3"
 *                                  "/home/file.sqlite3"
 *                                  "file:///home/file.sqlitedb"
 *                                  "C://home/file.sqlite3"
 *
 * @return                          the database 
 */
tb_database_sql_ref_t               tb_database_sql_init(tb_char_t const* url);

/*! exit database
 *
 * @param database                  the database handle
 */
tb_void_t                           tb_database_sql_exit(tb_database_sql_ref_t database);

/*! the database type
 *
 * @param database                  the database handle
 *
 * @return                          the database type
 */
tb_size_t                           tb_database_sql_type(tb_database_sql_ref_t database);

/*! open database
 *
 * @code
    tb_database_sql_ref_t database = tb_database_sql_init("sql://localhost/?type=mysql&username=xxxx&password=xxxx");
    if (database)
    {
        // open it
        if (tb_database_sql_open(database))
        {
            // done it
            // ...

            // close it
            tb_database_sql_clos(database);
        }
        tb_database_sql_exit(database);
    }
 * @endcode
 *
 * @param database                  the database handle
 *
 * @return                          tb_true or tb_false
 */
tb_bool_t                           tb_database_sql_open(tb_database_sql_ref_t database);

/*! clos database
 *
 * @param database                  the database handle
 */
tb_void_t                           tb_database_sql_clos(tb_database_sql_ref_t database);

/*! begin transaction
 *
 * @param database                  the database handle
 *
 * @return                          tb_true or tb_false
 */
tb_bool_t                           tb_database_sql_begin(tb_database_sql_ref_t database);

/*! commit transaction
 *
 * @param database                  the database handle
 *
 * @return                          tb_true or tb_false
 */
tb_bool_t                           tb_database_sql_commit(tb_database_sql_ref_t database);

/*! rollback transaction
 *
 * @param database                  the database handle
 *
 * @return                          tb_true or tb_false
 */
tb_bool_t                           tb_database_sql_rollback(tb_database_sql_ref_t database);

/*! the database state
 *
 * @param database                  the database handle
 *
 * @return                          the database state
 */
tb_size_t                           tb_database_sql_state(tb_database_sql_ref_t database);

/*! done database
 *
 * @code
 *
 * // done sql
 * if (!tb_database_sql_done(database, "select * from table"))
 * {
 *     // trace
 *     tb_trace_e("done sql failed, error: %s", tb_state_cstr(tb_database_sql_state(database)));
 *     return ;
 * }
 *
 * // load result
 * // ..
 *
 * @endcode
 *
 * @param database                  the database handle
 * @param sql                       the sql command
 *
 * @return                          tb_true or tb_false
 */
tb_bool_t                           tb_database_sql_done(tb_database_sql_ref_t database, tb_char_t const* sql);

/*! load the database result
 *
 * @code
 *
    // done sql
    // ..

    // load result
    tb_iterator_ref_t result = tb_database_sql_result_load(database, tb_true);
    if (result)
    {
        // walk result
        tb_for_all_if (tb_iterator_ref_t, row, result, row)
        {
            // walk values
            tb_for_all_if (tb_database_sql_value_t*, value, row, value)
            {
               tb_trace_i("name: %s, data: %s, at: %lux%lu", tb_database_sql_value_name(value), tb_database_sql_value_text(value), row_itor, item_itor);
            }
        }

        // exit result
        tb_database_sql_result_exit(result);
    }

    // load result
    tb_iterator_ref_t result = tb_database_sql_result_load(database, tb_false);
    if (result)
    {
        // walk result
        tb_for_all_if (tb_iterator_ref_t, row, result, row)
        {
            // field count
            tb_trace_i("count: %lu", tb_iterator_size(row));

            // id
            tb_database_sql_value_t const* id = tb_iterator_item(row, 0);
            if (id)
            {
                tb_trace_i("id: %d", tb_database_sql_value_int32(id));
            }

            // name
            tb_database_sql_value_t const* name = tb_iterator_item(row, 1);
            if (name)
            {
                tb_trace_i("name: %s", tb_database_sql_value_text(name));
            }

            // blob
            tb_database_sql_value_t const* blob = tb_iterator_item(row, 2);
            if (blob)
            {
                // data?
                tb_stream_ref_t stream = tb_null;
                if (tb_database_sql_value_blob(blob))
                {
                    // trace
                    tb_trace_i("[data: %p, size: %lu] ", tb_database_sql_value_blob(blob), tb_database_sql_value_size(blob));
                }
                // stream?
                else if ((stream = tb_database_sql_value_blob_stream(blob)))
                {
                    // trace
                    tb_trace_i("[stream: %p, size: %lld] ", stream, tb_stream_size(stream));

                    // read stream
                    // ...
                }
                // null?
                else
                {
                    // trace
                    tb_trace_i("[%s:null] ", tb_database_sql_value_name(blob));
                }
            }

        }

        // exit result
        tb_database_sql_result_exit(result);
    }

 * @endcode
 *
 * @param database                  the database handle
 * @param try_all                   try loading all result into memory
 *
 * @return                          the database result
 */
tb_iterator_ref_t                   tb_database_sql_result_load(tb_database_sql_ref_t database, tb_bool_t try_all);

/*! exit the database result
 *
 * @param database                  the database handle
 * @param result                    the database result
 */
tb_void_t                           tb_database_sql_result_exit(tb_database_sql_ref_t database, tb_iterator_ref_t result);

/*! init the database statement
 *
 * @param database                  the database handle
 * @param sql                       the sql command
 *
 * @return                          the statement handle
 */
tb_database_sql_statement_ref_t     tb_database_sql_statement_init(tb_database_sql_ref_t database, tb_char_t const* sql);

/*! exit the database statement
 *
 * @param database                  the database handle
 * @param statement                 the statement handle
 */
tb_void_t                           tb_database_sql_statement_exit(tb_database_sql_ref_t database, tb_database_sql_statement_ref_t statement);

/*! done the database statement
 *
 * @code
    tb_database_sql_statement_ref_t statement = tb_database_sql_statement_init(database, "select * from table where id=?");
    if (statement)
    {
        // bind arguments
        tb_database_sql_value_t list[1] = {0};
        tb_database_sql_value_set_int32(&list[0], 12345);
        if (tb_database_sql_statement_bind(database, statement, list, tb_arrayn(list)))
        {
            // done statement
            if (tb_database_sql_statement_done(database, statement))
            {
                // load result
                // ...
            }
        }

        // exit statement
        tb_database_sql_statement_exit(database, statement);
    }
 * @endcode
 *
 * @param database                  the database handle
 * @param statement                 the statement handle
 *
 * @return                          tb_true or tb_false
 */
tb_bool_t                           tb_database_sql_statement_done(tb_database_sql_ref_t database, tb_database_sql_statement_ref_t statement);

/*! bind the database statement argument
 *
 * @param database                  the database handle
 * @param statement                 the statement handle
 * @param list                      the argument value list
 * @param size                      the argument value count
 *
 * @return                          tb_true or tb_false
 */
tb_bool_t                           tb_database_sql_statement_bind(tb_database_sql_ref_t database, tb_database_sql_statement_ref_t statement, tb_database_sql_value_t const* list, tb_size_t size);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
