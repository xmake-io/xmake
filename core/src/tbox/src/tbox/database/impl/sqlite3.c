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
 * @file        sqlite3.c
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "sqlite3"
#define TB_TRACE_MODULE_DEBUG           (1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include <sqlite3.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the sqlite3 result row type
typedef struct __tb_database_sqlite3_result_row_t
{
    // the iterator
    tb_iterator_t                       itor;

    // the row
    tb_size_t                           row;

    // the col count
    tb_size_t                           count;

    // the col value
    tb_database_sql_value_t             value;

}tb_database_sqlite3_result_row_t;

// the sqlite3 result type
typedef struct __tb_database_sqlite3_result_t
{
    // the iterator
    tb_iterator_t                       itor;

    // the result
    tb_char_t**                         result;

    // the statement
    sqlite3_stmt*                       statement;

    // the row count
    tb_size_t                           count;

    // the row
    tb_database_sqlite3_result_row_t    row;

}tb_database_sqlite3_result_t;

// the sqlite3 type
typedef struct __tb_database_sqlite3_t
{
    // the base
    tb_database_sql_impl_t              base;

    // the database
    sqlite3*                            database;

    // the result
    tb_database_sqlite3_result_t        result;

}tb_database_sqlite3_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * library implementation
 */
static tb_handle_t tb_database_sqlite3_library_init(tb_cpointer_t* ppriv)
{
    // init it
    tb_int_t ok = SQLITE_OK;
    if ((ok = sqlite3_initialize()) != SQLITE_OK)
    {
        // trace
        tb_trace_e("init: sqlite3 library failed, error: %d", ok);
        return tb_null;
    }

    // ok
    return ppriv;
}
static tb_void_t tb_database_sqlite3_library_exit(tb_handle_t handle, tb_cpointer_t priv)
{
    // exit it
    sqlite3_shutdown();
}
static tb_handle_t tb_database_sqlite3_library_load()
{
    return tb_singleton_instance(TB_SINGLETON_TYPE_LIBRARY_SQLITE3, tb_database_sqlite3_library_init, tb_database_sqlite3_library_exit, tb_null, tb_null);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * state implementation
 */
static tb_size_t tb_database_sqlite3_state_from_errno(tb_size_t errno)
{
    // done
    tb_size_t state = TB_STATE_DATABASE_UNKNOWN_ERROR;
    switch (errno)
    {
    case SQLITE_NOTADB:
        state = TB_STATE_DATABASE_NO_SUCH_DATABASE;
        break;
    case SQLITE_PERM:
    case SQLITE_AUTH:
        state = TB_STATE_DATABASE_ACCESS_DENIED;
        break;
    case SQLITE_ERROR:
    case SQLITE_INTERNAL:
        break;
    default:
        tb_trace_e("unknown errno: %lu", errno);
        break;
    }

    // ok?
    return state;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * iterator implementation
 */
static tb_size_t tb_database_sqlite3_result_row_iterator_size(tb_iterator_ref_t iterator)
{
    // check
    tb_database_sqlite3_result_t* result = (tb_database_sqlite3_result_t*)iterator;
    tb_assert(result);

    // size
    return result->count;
}
static tb_size_t tb_database_sqlite3_result_row_iterator_head(tb_iterator_ref_t iterator)
{
    // head
    return 0;
}
static tb_size_t tb_database_sqlite3_result_row_iterator_tail(tb_iterator_ref_t iterator)
{
    // check
    tb_database_sqlite3_result_t* result = (tb_database_sqlite3_result_t*)iterator;
    tb_assert(result);

    // tail
    return result->count;
}
static tb_size_t tb_database_sqlite3_result_row_iterator_prev(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_database_sqlite3_result_t* result = (tb_database_sqlite3_result_t*)iterator;
    tb_assert(result);
    tb_assert_and_check_return_val(itor && itor <= result->count, result->count);

    // cannot be the statement result
    tb_assert_and_check_return_val(!result->statement, result->count);

    // prev
    return itor - 1;
}
static tb_size_t tb_database_sqlite3_result_row_iterator_next(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_database_sqlite3_result_t* result = (tb_database_sqlite3_result_t*)iterator;
    tb_assert(result);
    tb_assert_and_check_return_val(itor < result->count, result->count);

    // statement result?
    if (result->statement)
    {
        // step statement
        tb_int_t ok = sqlite3_step(result->statement);

        // end?
        if (ok != SQLITE_ROW) 
        {
            // reset it 
            if (SQLITE_OK != sqlite3_reset(result->statement))
            {
                // the sqlite
                tb_database_sqlite3_t* sqlite = (tb_database_sqlite3_t*)iterator->priv;
                if (sqlite)
                {
                    // save state
                    sqlite->base.state = tb_database_sqlite3_state_from_errno(sqlite3_errcode(sqlite->database));

                    // trace
                    tb_trace_e("statement: reset failed, error[%d]: %s", sqlite3_errcode(sqlite->database), sqlite3_errmsg(sqlite->database));
                }
            }

            // tail
            return result->count;
        }
    }

    // next
    return itor + 1;
}
static tb_pointer_t tb_database_sqlite3_result_row_iterator_item(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_database_sqlite3_result_t* result = (tb_database_sqlite3_result_t*)iterator;
    tb_assert_and_check_return_val(result && (result->result || result->statement) && itor < result->count, tb_null);

    // save the row
    result->row.row = itor;

    // the row iterator
    return (tb_pointer_t)&result->row;
}
static tb_size_t tb_database_sqlite3_result_col_iterator_size(tb_iterator_ref_t iterator)
{
    // check
    tb_database_sqlite3_result_row_t* row = (tb_database_sqlite3_result_row_t*)iterator;
    tb_assert_and_check_return_val(row, 0);

    // size
    return row->count;
}
static tb_size_t tb_database_sqlite3_result_col_iterator_head(tb_iterator_ref_t iterator)
{
    // check
    tb_database_sqlite3_result_row_t* row = (tb_database_sqlite3_result_row_t*)iterator;
    tb_assert_and_check_return_val(row, 0);

    // head
    return 0;
}
static tb_size_t tb_database_sqlite3_result_col_iterator_tail(tb_iterator_ref_t iterator)
{
    // check
    tb_database_sqlite3_result_row_t* row = (tb_database_sqlite3_result_row_t*)iterator;
    tb_assert_and_check_return_val(row, 0);

    // tail
    return row->count;
}
static tb_size_t tb_database_sqlite3_result_col_iterator_prev(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_database_sqlite3_result_row_t* row = (tb_database_sqlite3_result_row_t*)iterator;
    tb_assert_and_check_return_val(row && itor && itor <= row->count, 0);

    // prev
    return itor - 1;
}
static tb_size_t tb_database_sqlite3_result_col_iterator_next(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_database_sqlite3_result_row_t* row = (tb_database_sqlite3_result_row_t*)iterator;
    tb_assert_and_check_return_val(row && itor < row->count, row->count);

    // next
    return itor + 1;
}
static tb_pointer_t tb_database_sqlite3_result_col_iterator_item(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_database_sqlite3_result_row_t* row = (tb_database_sqlite3_result_row_t*)iterator;
    tb_assert_and_check_return_val(row && itor < row->count, tb_null);

    // the sqlite
    tb_database_sqlite3_t* sqlite = (tb_database_sqlite3_t*)iterator->priv;
    tb_assert_and_check_return_val(sqlite, tb_null);

    // result?
    if (sqlite->result.result)
    {
        // init value
        tb_database_sql_value_name_set(&row->value, (tb_char_t const*)sqlite->result.result[itor]);
        tb_database_sql_value_set_text(&row->value, (tb_char_t const*)sqlite->result.result[((1 + sqlite->result.row.row) * row->count) + itor], 0);
        return (tb_pointer_t)&row->value;
    }
    // statement result?
    else if (sqlite->result.statement)
    {
        // init name
        tb_database_sql_value_name_set(&row->value, sqlite3_column_name(sqlite->result.statement, (tb_int_t)itor));

        // init type
        tb_size_t type = sqlite3_column_type(sqlite->result.statement, (tb_int_t)itor);
        switch (type)
        {
        case SQLITE_INTEGER:
            tb_database_sql_value_set_int32(&row->value, sqlite3_column_int(sqlite->result.statement, (tb_int_t)itor));
            break;
        case SQLITE_TEXT:
            tb_database_sql_value_set_text(&row->value, (tb_char_t const*)sqlite3_column_text(sqlite->result.statement, (tb_int_t)itor), sqlite3_column_bytes(sqlite->result.statement, (tb_int_t)itor));
            break;
        case SQLITE_FLOAT:
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
            tb_database_sql_value_set_double(&row->value, sqlite3_column_double(sqlite->result.statement, (tb_int_t)itor));
            break;
#else
            // trace
            tb_trace1_e("float type is not supported, at col: %lu, please enable float config!", itor);
            return tb_null;
#endif
        case SQLITE_BLOB:
            tb_database_sql_value_set_blob32(&row->value, (tb_byte_t const*)sqlite3_column_blob(sqlite->result.statement, (tb_int_t)itor), sqlite3_column_bytes(sqlite->result.statement, (tb_int_t)itor), tb_null);
            break;
        case SQLITE_NULL:
            tb_database_sql_value_set_null(&row->value);
            break;
        default:
            tb_trace_e("unknown field type: %s, at col: %lu", type, itor);
            return tb_null;
        }

        // ok
        return (tb_pointer_t)&row->value;
    }

    // failed
    tb_assert(0);
    return tb_null;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static __tb_inline__ tb_database_sqlite3_t* tb_database_sqlite3_cast(tb_database_sql_impl_t* database)
{
    // check
    tb_assert_and_check_return_val(database && database->type == TB_DATABASE_SQL_TYPE_SQLITE3, tb_null);

    // cast
    return (tb_database_sqlite3_t*)database;
}
static tb_bool_t tb_database_sqlite3_open(tb_database_sql_impl_t* database)
{
    // check
    tb_database_sqlite3_t* sqlite = tb_database_sqlite3_cast(database);
    tb_assert_and_check_return_val(sqlite, tb_false);

    // done
    tb_bool_t           ok = tb_false;
    tb_char_t const*    path = tb_null;
    do
    {
        // the database path
        path = tb_url_cstr(&database->url);
        tb_assert_and_check_break(path);

        // load sqlite3 library
        if (!tb_database_sqlite3_library_load()) break;

        // open database
        if (SQLITE_OK != sqlite3_open_v2(path, &sqlite->database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, tb_null) || !sqlite->database) 
        {
            // error
            if (sqlite->database) 
            {
                // save state
                sqlite->base.state = tb_database_sqlite3_state_from_errno(sqlite3_errcode(sqlite->database));

                // trace
                tb_trace_e("open: %s failed, error[%d]: %s", path, sqlite3_errcode(sqlite->database), sqlite3_errmsg(sqlite->database));
            }
            break;
        }

        // ok
        ok = tb_true;

    } while (0);

    // trace
    tb_trace_d("open: %s: %s", path, ok? "ok" : "no");

    // ok?
    return ok;
}
static tb_void_t tb_database_sqlite3_clos(tb_database_sql_impl_t* database)
{
    // check
    tb_database_sqlite3_t* sqlite = tb_database_sqlite3_cast(database);
    tb_assert_and_check_return(sqlite);
    
    // exit result first if exists
    if (sqlite->result.result) sqlite3_free_table(sqlite->result.result);
    sqlite->result.result = tb_null;

    // close database
    if (sqlite->database) sqlite3_close(sqlite->database);
    sqlite->database = tb_null;
}
static tb_void_t tb_database_sqlite3_exit(tb_database_sql_impl_t* database)
{
    // check
    tb_database_sqlite3_t* sqlite = tb_database_sqlite3_cast(database);
    tb_assert_and_check_return(sqlite);

    // close it first
    tb_database_sqlite3_clos(database);

    // exit url
    tb_url_exit(&database->url);

    // exit it
    tb_free(sqlite);
}
static tb_bool_t tb_database_sqlite3_begin(tb_database_sql_impl_t* database)
{
    // check
    tb_database_sqlite3_t* sqlite = tb_database_sqlite3_cast(database);
    tb_assert_and_check_return_val(sqlite && sqlite->database, tb_false);

    // done commit
    if (SQLITE_OK != sqlite3_exec(sqlite->database, "begin;", tb_null, tb_null, tb_null))
    {
        // save state
        sqlite->base.state = tb_database_sqlite3_state_from_errno(sqlite3_errcode(sqlite->database));

        // trace
        tb_trace_e("begin: failed, error[%d]: %s", sqlite3_errcode(sqlite->database), sqlite3_errmsg(sqlite->database));
        return tb_false;
    }

    // ok
    return tb_true;
}
static tb_bool_t tb_database_sqlite3_commit(tb_database_sql_impl_t* database)
{
    // check
    tb_database_sqlite3_t* sqlite = tb_database_sqlite3_cast(database);
    tb_assert_and_check_return_val(sqlite && sqlite->database, tb_false);

    // done commit
    if (SQLITE_OK != sqlite3_exec(sqlite->database, "commit;", tb_null, tb_null, tb_null))
    {
        // save state
        sqlite->base.state = tb_database_sqlite3_state_from_errno(sqlite3_errcode(sqlite->database));

        // trace
        tb_trace_e("commit: failed, error[%d]: %s", sqlite3_errcode(sqlite->database), sqlite3_errmsg(sqlite->database));
        return tb_false;
    }

    // ok
    return tb_true;
}
static tb_bool_t tb_database_sqlite3_rollback(tb_database_sql_impl_t* database)
{
    // check
    tb_database_sqlite3_t* sqlite = tb_database_sqlite3_cast(database);
    tb_assert_and_check_return_val(sqlite && sqlite->database, tb_false);

    // done rollback
    if (SQLITE_OK != sqlite3_exec(sqlite->database, "rollback;", tb_null, tb_null, tb_null))
    {
        // save state
        sqlite->base.state = tb_database_sqlite3_state_from_errno(sqlite3_errcode(sqlite->database));

        // trace
        tb_trace_e("rollback: failed, error[%d]: %s", sqlite3_errcode(sqlite->database), sqlite3_errmsg(sqlite->database));
        return tb_false;
    }

    // ok
    return tb_true;
}
static tb_bool_t tb_database_sqlite3_done(tb_database_sql_impl_t* database, tb_char_t const* sql)
{
    // check
    tb_database_sqlite3_t* sqlite = tb_database_sqlite3_cast(database);
    tb_assert_and_check_return_val(sqlite && sqlite->database && sql, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // exit result first if exists
        if (sqlite->result.result) sqlite3_free_table(sqlite->result.result);
        sqlite->result.result = tb_null;

        // clear the lasr statement first
        sqlite->result.statement = tb_null;

        // clear the result row count first
        sqlite->result.count = 0;

        // clear the result col count first
        sqlite->result.row.count = 0;

        // done sql
        tb_int_t    row_count = 0;
        tb_int_t    col_count = 0;
        tb_char_t*  error = tb_null;
        if (SQLITE_OK != sqlite3_get_table(sqlite->database, sql, &sqlite->result.result, &row_count, &col_count, &error))
        {
            // save state
            sqlite->base.state = tb_database_sqlite3_state_from_errno(sqlite3_errcode(sqlite->database));

            // trace
            tb_trace_e("done: sql: %s failed, error[%d]: %s", sql, sqlite3_errcode(sqlite->database), error);

            // exit error
            if (error) sqlite3_free(error);
            break;
        }

        // no result?
        if (!row_count)
        {
            // exit result
            if (sqlite->result.result) sqlite3_free_table(sqlite->result.result);
            sqlite->result.result = tb_null;

            // trace
            tb_trace_d("done: sql: %s: ok", sql);

            // ok
            ok = tb_true;
            break;
        }

        // save the result iterator mode
        sqlite->result.itor.mode = TB_ITERATOR_MODE_RACCESS | TB_ITERATOR_MODE_READONLY;

        // save result row count
        sqlite->result.count = row_count;

        // save result col count
        sqlite->result.row.count = col_count;

        // trace
        tb_trace_d("done: sql: %s: ok", sql);

        // ok
        ok = tb_true;
    
    } while (0);
    
    // ok?
    return ok;
}
static tb_void_t tb_database_sqlite3_result_exit(tb_database_sql_impl_t* database, tb_iterator_ref_t result)
{
    // check
    tb_database_sqlite3_result_t* sqlite3_result = (tb_database_sqlite3_result_t*)result;
    tb_assert_and_check_return(sqlite3_result);

    // exit result
    if (sqlite3_result->result) sqlite3_free_table(sqlite3_result->result);
    sqlite3_result->result = tb_null;

    // clear the statement
    sqlite3_result->statement = tb_null;

    // clear result
    sqlite3_result->count = 0;
    sqlite3_result->row.count = 0;
}
static tb_iterator_ref_t tb_database_sqlite3_result_load(tb_database_sql_impl_t* database, tb_bool_t try_all)
{
    // check
    tb_database_sqlite3_t* sqlite = tb_database_sqlite3_cast(database);
    tb_assert_and_check_return_val(sqlite && sqlite->database, tb_null);

    // ok?
    return (sqlite->result.result || sqlite->result.statement)? (tb_iterator_ref_t)&sqlite->result : tb_null;
}
static tb_void_t tb_database_sqlite3_statement_exit(tb_database_sql_impl_t* database, tb_database_sql_statement_ref_t statement)
{
    // exit statement
    if (statement) sqlite3_finalize((sqlite3_stmt*)statement);
}
static tb_database_sql_statement_ref_t tb_database_sqlite3_statement_init(tb_database_sql_impl_t* database, tb_char_t const* sql)
{
    // check
    tb_database_sqlite3_t* sqlite = tb_database_sqlite3_cast(database);
    tb_assert_and_check_return_val(sqlite && sqlite->database && sql, tb_null);

    // init statement
    sqlite3_stmt* statement = tb_null;
    if (SQLITE_OK != sqlite3_prepare_v2(sqlite->database, sql, -1, &statement, 0))
    {
        // save state
        sqlite->base.state = tb_database_sqlite3_state_from_errno(sqlite3_errcode(sqlite->database));

        // trace
        tb_trace_e("statement: init %s failed, error[%d]: %s", sql, sqlite3_errcode(sqlite->database), sqlite3_errmsg(sqlite->database));
    }

    // ok?
    return (tb_database_sql_statement_ref_t)statement;
}
static tb_bool_t tb_database_sqlite3_statement_done(tb_database_sql_impl_t* database, tb_database_sql_statement_ref_t statement)
{
    // check
    tb_database_sqlite3_t* sqlite = tb_database_sqlite3_cast(database);
    tb_assert_and_check_return_val(sqlite && sqlite->database && statement, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // exit result first if exists
        if (sqlite->result.result) sqlite3_free_table(sqlite->result.result);
        sqlite->result.result = tb_null;

        // clear the last statement first
        sqlite->result.statement = tb_null;

        // clear the result row count first
        sqlite->result.count = 0;

        // clear the result col count first
        sqlite->result.row.count = 0;

        // step statement
        tb_int_t result = sqlite3_step((sqlite3_stmt*)statement);
        tb_assert_and_check_break(result == SQLITE_DONE || result == SQLITE_ROW);

        // exists result?
        if (result == SQLITE_ROW)
        {
            // save the result iterator mode
            sqlite->result.itor.mode = TB_ITERATOR_MODE_FORWARD | TB_ITERATOR_MODE_READONLY;

            // save statement for iterating it
            sqlite->result.statement = (sqlite3_stmt*)statement;

            // save result row count
            sqlite->result.count = (tb_size_t)-1;

            // save result col count
            sqlite->result.row.count = sqlite3_column_count((sqlite3_stmt*)statement);
        }
        else
        {
            // reset it 
            if (SQLITE_OK != sqlite3_reset((sqlite3_stmt*)statement))
            {
                // save state
                sqlite->base.state = tb_database_sqlite3_state_from_errno(sqlite3_errcode(sqlite->database));

                // trace
                tb_trace_e("statement: reset failed, error[%d]: %s", sqlite3_errcode(sqlite->database), sqlite3_errmsg(sqlite->database));

                // failed
                break;
            }
        }

        // ok
        ok = tb_true;

    } while (0);

    // ok?
    return ok;
}
static tb_void_t tb_database_sqlite3_statement_bind_exit(tb_pointer_t data)
{
    // trace
    tb_trace_d("bind: exit: %p", data);

    // exit it
    if (data) tb_free(data);
}
static tb_bool_t tb_database_sqlite3_statement_bind(tb_database_sql_impl_t* database, tb_database_sql_statement_ref_t statement, tb_database_sql_value_t const* list, tb_size_t size)
{
    // check
    tb_database_sqlite3_t* sqlite = tb_database_sqlite3_cast(database);
    tb_assert_and_check_return_val(sqlite && sqlite->database && statement && list && size, tb_false);

    // the param count
    tb_size_t param_count = (tb_size_t)sqlite3_bind_parameter_count((sqlite3_stmt*)statement);
    tb_assert_and_check_return_val(size == param_count, tb_false);
   
    // walk
    tb_size_t i = 0;
    for (i = 0; i < size; i++)
    {
        // the value
        tb_database_sql_value_t const* value = &list[i];

        // done
        tb_int_t    ok = SQLITE_ERROR;
        tb_byte_t*  data = tb_null;
        switch (value->type)
        {
        case TB_DATABASE_SQL_VALUE_TYPE_TEXT:
            tb_trace_i("sqlite3: test %lu %s", i, value->u.text.data);
            ok = sqlite3_bind_text((sqlite3_stmt*)statement, (tb_int_t)(i + 1), value->u.text.data, (tb_int_t)tb_database_sql_value_size(value), tb_null);
            break;
        case TB_DATABASE_SQL_VALUE_TYPE_INT64:
        case TB_DATABASE_SQL_VALUE_TYPE_UINT64:
            ok = sqlite3_bind_int64((sqlite3_stmt*)statement, (tb_int_t)(i + 1), tb_database_sql_value_int64(value));
            break;
        case TB_DATABASE_SQL_VALUE_TYPE_INT32:
        case TB_DATABASE_SQL_VALUE_TYPE_INT16:
        case TB_DATABASE_SQL_VALUE_TYPE_INT8:
        case TB_DATABASE_SQL_VALUE_TYPE_UINT32:
        case TB_DATABASE_SQL_VALUE_TYPE_UINT16:
        case TB_DATABASE_SQL_VALUE_TYPE_UINT8:
            ok = sqlite3_bind_int((sqlite3_stmt*)statement, (tb_int_t)(i + 1), (tb_int_t)tb_database_sql_value_int32(value));
            break;
        case TB_DATABASE_SQL_VALUE_TYPE_BLOB16:
        case TB_DATABASE_SQL_VALUE_TYPE_BLOB8:
            ok = sqlite3_bind_blob((sqlite3_stmt*)statement, (tb_int_t)(i + 1), value->u.blob.data, (tb_int_t)value->u.blob.size, tb_null);
            break;
        case TB_DATABASE_SQL_VALUE_TYPE_BLOB32:
            {
                if (value->u.blob.stream)
                {
                    // done
                    do
                    {
                        // the stream size
                        tb_hong_t size = tb_stream_size(value->u.blob.stream);
                        tb_assert_and_check_break(size >= 0);

                        // make data
                        data = tb_malloc0_bytes((tb_size_t)size);
                        tb_assert_and_check_break(data);

                        // read data
                        if (!tb_stream_bread(value->u.blob.stream, data, (tb_size_t)size)) break;

                        // bind it
                        ok = sqlite3_bind_blob((sqlite3_stmt*)statement, (tb_int_t)(i + 1), data, (tb_int_t)size, tb_database_sqlite3_statement_bind_exit);

                    } while (0);
                }
                else ok = sqlite3_bind_blob((sqlite3_stmt*)statement, (tb_int_t)(i + 1), value->u.blob.data, (tb_int_t)value->u.blob.size, tb_null);
            }
            break;
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
        case TB_DATABASE_SQL_VALUE_TYPE_FLOAT:
        case TB_DATABASE_SQL_VALUE_TYPE_DOUBLE:
            ok = sqlite3_bind_double((sqlite3_stmt*)statement, (tb_int_t)(i + 1), (tb_double_t)tb_database_sql_value_double(value));
            break;
#endif
        case TB_DATABASE_SQL_VALUE_TYPE_NULL:
            ok = sqlite3_bind_null((sqlite3_stmt*)statement, (tb_int_t)(i + 1));
            break;
        default:
            tb_trace_e("statement: bind: unknown value type: %lu", value->type);
            break;
        }

        // failed?
        if (SQLITE_OK != ok)
        {
            // exit data
            if (data) tb_free(data);
            data = tb_null;

            // save state
            sqlite->base.state = tb_database_sqlite3_state_from_errno(sqlite3_errcode(sqlite->database));

            // trace
            tb_trace_e("statement: bind value[%lu] failed, error[%d]: %s", i, sqlite3_errcode(sqlite->database), sqlite3_errmsg(sqlite->database));
            break;
        }
    }

    // ok?
    return (i == size)? tb_true : tb_false;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_size_t tb_database_sqlite3_probe(tb_url_ref_t url)
{
    // check
    tb_assert_and_check_return_val(url, 0);

    // done
    tb_size_t           score = 0;
    tb_stream_ref_t  stream = tb_null;
    do
    {
        // the url arguments
        tb_char_t const* args = tb_url_args(url);
        if (args)
        {
            // find the database type
            tb_char_t const* ptype = tb_stristr(args, "type=");
            if (ptype && !tb_strnicmp(ptype + 5, "sqlite3", 7))
            {
                // ok
                score = 100;
                break;
            }
        }

        // has host or port? no sqlite3
        if (tb_url_host(url) || tb_url_port(url)) break;

        // the database path
        tb_char_t const* path = tb_url_cstr((tb_url_ref_t)url);
        tb_assert_and_check_break(path);

        // is file?
        if (tb_url_protocol(url) == TB_URL_PROTOCOL_FILE) score += 20;

        // init stream
        stream = tb_stream_init_from_url(path);
        tb_assert_and_check_break(stream);

        // open stream
        if (!tb_stream_open(stream)) break;

        // read head
        tb_char_t head[16] = {0};
        if (!tb_stream_bread(stream, (tb_byte_t*)head, 15)) break;

        // is sqlite3?
        if (!tb_stricmp(head, "SQLite format 3")) score = 100;

    } while (0);

    // exit stream
    if (stream) tb_stream_exit(stream);
    stream = tb_null;

    // trace
    tb_trace_d("probe: %s, score: %lu", tb_url_cstr((tb_url_ref_t)url), score);

    // ok?
    return score;
}
tb_database_sql_ref_t tb_database_sqlite3_init(tb_url_ref_t url)
{
    // check
    tb_assert_and_check_return_val(url, tb_null);

    // done
    tb_bool_t               ok = tb_false;
    tb_database_sqlite3_t*  sqlite = tb_null;
    do
    {
        // make database
        sqlite = tb_malloc0_type(tb_database_sqlite3_t);
        tb_assert_and_check_break(sqlite);

        // init database
        sqlite->base.type           = TB_DATABASE_SQL_TYPE_SQLITE3;
        sqlite->base.open           = tb_database_sqlite3_open;
        sqlite->base.clos           = tb_database_sqlite3_clos;
        sqlite->base.exit           = tb_database_sqlite3_exit;
        sqlite->base.done           = tb_database_sqlite3_done;
        sqlite->base.begin          = tb_database_sqlite3_begin;
        sqlite->base.commit         = tb_database_sqlite3_commit;
        sqlite->base.rollback       = tb_database_sqlite3_rollback;
        sqlite->base.result_load    = tb_database_sqlite3_result_load;
        sqlite->base.result_exit    = tb_database_sqlite3_result_exit;
        sqlite->base.statement_init = tb_database_sqlite3_statement_init;
        sqlite->base.statement_exit = tb_database_sqlite3_statement_exit;
        sqlite->base.statement_done = tb_database_sqlite3_statement_done;
        sqlite->base.statement_bind = tb_database_sqlite3_statement_bind;

        // init row operation
        static tb_iterator_op_t row_op = 
        {
            tb_database_sqlite3_result_row_iterator_size
        ,   tb_database_sqlite3_result_row_iterator_head
        ,   tb_null
        ,   tb_database_sqlite3_result_row_iterator_tail
        ,   tb_database_sqlite3_result_row_iterator_prev
        ,   tb_database_sqlite3_result_row_iterator_next
        ,   tb_database_sqlite3_result_row_iterator_item
        ,   tb_null
        ,   tb_null
        ,   tb_null
        ,   tb_null
        };

        // init col operation
        static tb_iterator_op_t col_op = 
        {
            tb_database_sqlite3_result_col_iterator_size
        ,   tb_database_sqlite3_result_col_iterator_head
        ,   tb_null
        ,   tb_database_sqlite3_result_col_iterator_tail
        ,   tb_database_sqlite3_result_col_iterator_prev
        ,   tb_database_sqlite3_result_col_iterator_next
        ,   tb_database_sqlite3_result_col_iterator_item
        ,   tb_null
        ,   tb_null
        ,   tb_null
        ,   tb_null
        };

        // init result row iterator
        sqlite->result.itor.priv     = (tb_pointer_t)sqlite;
        sqlite->result.itor.step     = 0;
        sqlite->result.itor.mode     = 0;
        sqlite->result.itor.op       = &row_op;

        // init result col iterator
        sqlite->result.row.itor.priv = (tb_pointer_t)sqlite;
        sqlite->result.row.itor.step = 0;
        sqlite->result.row.itor.mode = TB_ITERATOR_MODE_RACCESS | TB_ITERATOR_MODE_READONLY;
        sqlite->result.row.itor.op   = &col_op;

        // init url
        if (!tb_url_init(&sqlite->base.url)) break;

        // copy url
        tb_url_copy(&sqlite->base.url, url);

        // init state
        sqlite->base.state = TB_STATE_OK;

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok) 
    {
        // exit database
        if (sqlite) tb_database_sqlite3_exit((tb_database_sql_impl_t*)sqlite);
        sqlite = tb_null;
    }

    // ok?
    return (tb_database_sql_ref_t)sqlite;
}
