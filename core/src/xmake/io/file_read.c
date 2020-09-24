/*!A cross-platform build utility based on Lua
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
 * Copyright (C) 2015-2020, TBOOX Open Source Group.
 *
 * @author      OpportunityLiu, ruki
 * @file        file_read.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "file_read"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */
typedef enum __xm_pushline_state_e
{
    PL_EOF,
    PL_FIN,
    PL_CONL,
    PL_FAIL,

} xm_pushline_state_e;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_long_t xm_io_file_buffer_readline(tb_stream_ref_t stream, tb_buffer_ref_t line)
{
    // check
    tb_assert_and_check_return_val(stream && line, -1);

    // read line and reserve crlf
    tb_bool_t   eof = tb_false;
    tb_hize_t   offset = 0;
    tb_byte_t*  data = tb_null;
    tb_hong_t   size = tb_stream_size(stream);
    while (size < 0 || (offset = tb_stream_offset(stream)) < size)
    {
        tb_long_t real = tb_stream_peek(stream, &data, TB_STREAM_BLOCK_MAXN);
        if (real > 0)
        {
            tb_char_t const* e = tb_strnchr((tb_char_t const*)data, real, '\n');
            if (e)
            {
                tb_size_t n = (tb_byte_t const*)e + 1 - data;
                if (!tb_stream_skip(stream, n)) return -1;
                tb_buffer_memncat(line, data, n);
                break;
            }
            else
            {
                if (!tb_stream_skip(stream, real)) return -1;
                tb_buffer_memncat(line, data, real);
            }
        }
        else if (!real)
        {
            real = tb_stream_wait(stream, TB_STREAM_WAIT_READ, -1);
            if (real <= 0)
            {
                eof = tb_true;
                break;
            }
        }
        else
        {
            eof = tb_true;
            break;
        }
    }

    // ok?
    tb_size_t linesize = tb_buffer_size(line);
    if (linesize) return linesize;
    else return (eof || tb_stream_beof(stream))? -1 : 0;
}
static tb_int_t xm_io_file_buffer_pushline(tb_buffer_ref_t buf, xm_io_file_t* file, tb_char_t const* continuation, tb_bool_t keep_crlf)
{
    // check
    tb_assert(buf && file && continuation && xm_io_file_is_file(file) && file->file_ref);

    // is binary?
    tb_bool_t is_binary = file->encoding == XM_IO_FILE_ENCODING_BINARY;
    if (is_binary)
    {
        continuation = "";
        keep_crlf = tb_true;
    }

    // clear line buffer
    tb_buffer_clear(&file->rcache);

    // read line data
    tb_long_t size = xm_io_file_buffer_readline(file->file_ref, &file->rcache);

    // translate line data
    tb_int_t    result = PL_FAIL;
    tb_char_t*  data = tb_null;
    tb_size_t   conlen = tb_strlen(continuation);
    do
    {
        // eof?
        if (size < 0)
        {
            result = PL_EOF;
            break;
        }

        // patch two '\0'
        tb_buffer_memncat(&file->rcache, (tb_byte_t const*)"\0\0", 2);

        // get line data
        data = (tb_char_t*)tb_buffer_data(&file->rcache);
        tb_assert_and_check_break(data);

        // no lf found
        if (size > 0 && data[size - 1] != '\n')
            result = PL_FIN;
        else if (size > 1)
        {
            // crlf? => lf
            if (!is_binary && data[size - 2] == '\r')
            {
                data[size - 2] = '\n';
                size--;
            }

            // has continuation?
            tb_bool_t has_conline = conlen && size >= conlen + 1 && tb_strncmp(continuation, (tb_char_t const*)(data + size - conlen - 1), conlen) == 0;

            // do not keep crlf, strip the last lf
            if (!keep_crlf && !has_conline) size--;

            // strip it if has continuation?
            if (has_conline) size -= conlen + 1;
            data[size] = '\0';

            result = has_conline ? PL_CONL : PL_FIN;
        }
        else
        {
            // a single '\n'
            if (!keep_crlf) size = 0;
            result = PL_FIN;
        }

    } while (0);

    // push line data
    if (data && size > 0 && (result == PL_FIN || result == PL_CONL))
        tb_buffer_memncat(buf, (tb_byte_t const*)data, size);

    // return result
    return result;
}
static tb_int_t xm_io_file_read_all_directly(lua_State* lua, xm_io_file_t* file)
{
    // check
    tb_assert(lua && file && xm_io_file_is_file(file) && file->file_ref);

    // init buffer
    tb_buffer_t buf;
    if (!tb_buffer_init(&buf))
        xm_io_return_error(lua, "init buffer failed!");

    // read all
    tb_byte_t           data[TB_STREAM_BLOCK_MAXN];
    tb_stream_ref_t     stream = file->file_ref;
    while (!tb_stream_beof(stream))
    {
        tb_long_t real = tb_stream_read(stream, data, sizeof(data));
        if (real > 0)
            tb_buffer_memncat(&buf, data, real);
        else if (!real)
        {
            real = tb_stream_wait(stream, TB_STREAM_WAIT_READ, -1);
            tb_check_break(real > 0);
        }
        else break;
    }

    if (tb_buffer_size(&buf))
        lua_pushlstring(lua, (tb_char_t const*)tb_buffer_data(&buf), tb_buffer_size(&buf));
    else lua_pushliteral(lua, "");
    tb_buffer_exit(&buf);
    return 1;
}
static tb_int_t xm_io_file_read_all(lua_State* lua, xm_io_file_t* file, tb_char_t const* continuation)
{
    // check
    tb_assert(lua && file && continuation && xm_io_file_is_file(file) && file->file_ref);

    // is binary? read all directly
    tb_bool_t is_binary = file->encoding == XM_IO_FILE_ENCODING_BINARY;
    if (is_binary)
        return xm_io_file_read_all_directly(lua, file);

    // init buffer
    tb_buffer_t buf;
    if (!tb_buffer_init(&buf))
        xm_io_return_error(lua, "init buffer failed!");

    // read all
    tb_bool_t has_content = tb_false;
    while (1)
    {
        switch (xm_io_file_buffer_pushline(&buf, file, continuation, tb_true))
        {
        case PL_EOF:
            if (!has_content) lua_pushliteral(lua, "");
            else lua_pushlstring(lua, (tb_char_t const*)tb_buffer_data(&buf), tb_buffer_size(&buf));
            tb_buffer_exit(&buf);
            return 1;
        case PL_FIN:
        case PL_CONL:
            has_content = tb_true;
            continue;
        case PL_FAIL:
        default:
            tb_buffer_exit(&buf);
            xm_io_return_error(lua, "failed to read all");
            break;
        }
    }
}

static tb_int_t xm_io_file_read_line(lua_State* lua, xm_io_file_t* file, tb_char_t const* continuation, tb_bool_t keep_crlf)
{
    // check
    tb_assert(lua && file && continuation && xm_io_file_is_file(file) && file->file_ref);

    // init buffer
    tb_buffer_t buf;
    if (!tb_buffer_init(&buf))
        xm_io_return_error(lua, "init buffer failed!");

    // read line
    tb_bool_t has_content = tb_false;
    while (1)
    {
        switch (xm_io_file_buffer_pushline(&buf, file, continuation, keep_crlf))
        {
        case PL_EOF:
            if (!has_content) lua_pushnil(lua);
            else lua_pushlstring(lua, (tb_char_t const*)tb_buffer_data(&buf), tb_buffer_size(&buf));
            tb_buffer_exit(&buf);
            return 1;
        case PL_FIN:
            lua_pushlstring(lua, (tb_char_t const*)tb_buffer_data(&buf), tb_buffer_size(&buf));
            tb_buffer_exit(&buf);
            return 1;
        case PL_CONL:
            has_content = tb_true;
            continue;
        case PL_FAIL:
        default:
            tb_buffer_exit(&buf);
            xm_io_return_error(lua, "failed to readline");
            break;
        }
    }
}

static tb_int_t xm_io_file_read_n(lua_State* lua, xm_io_file_t* file, tb_char_t const* continuation, tb_long_t n)
{
    // check
    tb_assert(lua && file && continuation && xm_io_file_is_file(file) && file->file_ref);

    // check continuation
    if (*continuation != '\0')
        xm_io_return_error(lua, "continuation is not supported for read number of bytes");

    // check encoding
    if (file->encoding != XM_IO_FILE_ENCODING_BINARY)
        xm_io_return_error(lua, "read number of bytes only allows binary file, reopen with 'rb' and try again");

    tb_bool_t ok = tb_false;
    if (n == 0)
    {
        tb_byte_t* data = tb_null;
        if (tb_stream_need(file->file_ref, &data, 1))
        {
            lua_pushliteral(lua, "");
            ok = tb_true;
        }
    }
    else
    {
        tb_byte_t* bufptr = tb_buffer_resize(&file->rcache, n + 1);
        if (bufptr)
        {
            if (tb_stream_bread(file->file_ref, bufptr, n))
            {
                lua_pushlstring(lua, (tb_char_t const*)bufptr, n);
                ok = tb_true;
            }
        }
    }
    if (!ok) lua_pushnil(lua);
    return 1;
}

static tb_size_t xm_io_file_std_buffer_pushline(tb_buffer_ref_t buf, xm_io_file_t* file, tb_char_t const* continuation, tb_bool_t keep_crlf)
{
    // check
    tb_assert(buf && file && continuation && xm_io_file_is_std(file));

    // get input buffer
    tb_char_t strbuf[8192];
    tb_size_t buflen = 0;
    tb_size_t result = PL_FAIL;
    if (tb_stdfile_gets(file->std_ref, strbuf, tb_arrayn(strbuf) - 1))
        buflen = tb_strlen(strbuf);
    else return PL_EOF;

    tb_size_t conlen = tb_strlen(continuation);
    if (buflen > 0 && strbuf[buflen - 1] != '\n')
    {
        // end of file, no lf found
        result = PL_FIN;
    }
    else if (buflen > 1)
    {
        // crlf? => lf
        if (strbuf[buflen - 2] == '\r')
        {
            strbuf[buflen - 2] = '\n';
            buflen--;
        }

        // has continuation?
        tb_bool_t has_conline = conlen && buflen >= conlen + 1 && tb_strncmp(continuation, (strbuf + buflen - conlen - 1), conlen) == 0;

        // do not keep crlf, strip the last lf
        if (!keep_crlf && !has_conline) buflen--;

        // strip it if has continuation?
        if (has_conline) buflen -= conlen + 1;
            strbuf[buflen] = '\0';

        result = has_conline? PL_CONL : PL_FIN;
    }
    else
    {
        // a single '\n'
        if (!keep_crlf) buflen = 0;
        result = PL_FIN;
    }

    if (result == PL_FIN || result == PL_CONL)
        tb_buffer_memncat(buf, (tb_byte_t const*)strbuf, buflen);
    return result;
}

static tb_int_t xm_io_file_std_read_line(lua_State* lua, xm_io_file_t* file, tb_char_t const* continuation, tb_bool_t keep_crlf)
{
    // check
    tb_assert(lua && file && continuation && xm_io_file_is_std(file));

    // init buffer
    tb_buffer_t buf;
    if (!tb_buffer_init(&buf))
        xm_io_return_error(lua, "init buffer failed!");

    // read line
    tb_bool_t has_content = tb_false;
    while (1)
    {
        switch (xm_io_file_std_buffer_pushline(&buf, file, continuation, keep_crlf))
        {
        case PL_EOF:
            if (!has_content) lua_pushnil(lua);
            else lua_pushlstring(lua, (tb_char_t const*)tb_buffer_data(&buf), tb_buffer_size(&buf));
            tb_buffer_exit(&buf);
            return 1;
        case PL_FIN:
            lua_pushlstring(lua, (tb_char_t const*)tb_buffer_data(&buf), tb_buffer_size(&buf));
            tb_buffer_exit(&buf);
            return 1;
        case PL_CONL:
            has_content = tb_true;
            continue;
        case PL_FAIL:
        default:
            tb_buffer_exit(&buf);
            xm_io_return_error(lua, "failed to readline");
            break;
        }
    }
}

static tb_int_t xm_io_file_std_read_all(lua_State* lua, xm_io_file_t* file, tb_char_t const* continuation)
{
    // check
    tb_assert(lua && file && continuation && xm_io_file_is_std(file));

    // init buffer
    tb_buffer_t buf;
    if (!tb_buffer_init(&buf))
        xm_io_return_error(lua, "init buffer failed!");

    // read all
    tb_bool_t has_content = tb_false;
    while (1)
    {
        switch (xm_io_file_std_buffer_pushline(&buf, file, continuation, tb_true))
        {
        case PL_EOF:
            if (!has_content) lua_pushliteral(lua, "");
            else lua_pushlstring(lua, (tb_char_t const*)tb_buffer_data(&buf), tb_buffer_size(&buf));
            tb_buffer_exit(&buf);
            return 1;
        case PL_FIN:
        case PL_CONL:
            has_content = tb_true;
            continue;
        case PL_FAIL:
        default:
            tb_buffer_exit(&buf);
            xm_io_return_error(lua, "failed to readline");
            break;
        }
    }
}

static tb_int_t xm_io_file_std_read_n(lua_State* lua, xm_io_file_t* file, tb_char_t const* continuation, tb_long_t n)
{
    // check
    tb_assert(lua && file && continuation && xm_io_file_is_std(file));

    // check continuation
    if (*continuation != '\0')
        xm_io_return_error(lua, "continuation is not supported for std streams");

    // io.read(0)
    if (n == 0)
    {
        tb_char_t ch;
        if (!tb_stdfile_peek(file->std_ref, &ch))
            lua_pushnil(lua);
        else
            lua_pushliteral(lua, "");
        return 1;
    }

    // get line buffer
    tb_byte_t* buf_ptr = tb_buffer_resize(&file->rcache, (tb_size_t)n);
    tb_assert(buf_ptr);

    // io.read(n)
    if (tb_stdfile_read(file->std_ref, buf_ptr, (tb_size_t)n))
        lua_pushlstring(lua, (tb_char_t const*)buf_ptr, (size_t)n);
    else lua_pushnil(lua);
    return 1;
}

static tb_int_t xm_io_file_std_read_num(lua_State* lua, xm_io_file_t* file, tb_char_t const* continuation)
{
    // check
    tb_assert(lua && file && continuation && xm_io_file_is_std(file));

    // check continuation
    if (*continuation != '\0')
        xm_io_return_error(lua, "continuation is not supported for std streams");

    // read number
    tb_char_t strbuf[512];
    if (tb_stdfile_gets(file->std_ref, strbuf, tb_arrayn(strbuf)))
        lua_pushnumber(lua, tb_s10tod(strbuf)); // TODO check invalid float number string and push nil
    else lua_pushnil(lua);
    return 1;
}

/* io.file_read(file, [mode, [continuation]])
 * io.file_read(file, "all", "\\")
 * io.file_read(file, "L")
 * io.file_read(file, "l")
 * io.file_read(file, "n")
 * io.file_read(file, 10)
 */
tb_int_t xm_io_file_read(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // is user data?
    if (!lua_isuserdata(lua, 1))
        xm_io_return_error(lua, "read(invalid file)!");

    // get file
    xm_io_file_t* file = (xm_io_file_t*)lua_touserdata(lua, 1);
    tb_check_return_val(file, 0);

    // get arguments
    tb_char_t const* mode         = luaL_optstring(lua, 2, "l");
    tb_char_t const* continuation = luaL_optstring(lua, 3, "");
    tb_assert_and_check_return_val(mode && continuation, 0);

    tb_long_t count = -1;
    if (lua_isnumber(lua, 2))
    {
        count = (tb_long_t)lua_tointeger(lua, 2);
        if (count < 0) xm_io_return_error(lua, "invalid read size, must be positive nubmber or 0");
    }
    else if (*mode == '*')
        mode++;

    if (xm_io_file_is_file(file))
    {
        if (count >= 0) return xm_io_file_read_n(lua, file, continuation, count);
        switch (*mode)
        {
        case 'a': return xm_io_file_read_all(lua, file, continuation);
        case 'L': return xm_io_file_read_line(lua, file, continuation, tb_true);
        case 'n': xm_io_return_error(lua, "read number is not implemented");
        case 'l': return xm_io_file_read_line(lua, file, continuation, tb_false);
        default:
            xm_io_return_error(lua, "unknonwn read mode");
            return 0;
        }
    }
    else
    {
        if (count >= 0) return xm_io_file_std_read_n(lua, file, continuation, count);
        switch (*mode)
        {
        case 'a': return xm_io_file_std_read_all(lua, file, continuation);
        case 'L': return xm_io_file_std_read_line(lua, file, continuation, tb_true);
        case 'n': return xm_io_file_std_read_num(lua, file, continuation);
        case 'l': return xm_io_file_std_read_line(lua, file, continuation, tb_false);
        default:
            xm_io_return_error(lua, "unknonwn read mode");
            return 0;
        }
    }
}
