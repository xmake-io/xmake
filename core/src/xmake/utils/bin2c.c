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
 * Copyright (C) 2015-present, Xmake Open Source Community.
 *
 * @author      ruki
 * @file        bin2c.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "bin2c"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#define XM_BIN2C_DATA_SIZE      (8 * 1024)
#define XM_BIN2C_LINE_SIZE      (4 * 1024)
#define XM_BIN2C_LINEWIDTH_MAX  ((XM_BIN2C_LINE_SIZE - 2) / 6)

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */

// optimized hex conversion table
static tb_char_t const *xm_utils_bin2c_digits = "0123456789ABCDEF";

// inline hex conversion for better performance
static __tb_inline__ tb_void_t xm_utils_bin2c_write_hex(tb_char_t *str, tb_byte_t value) {
    str[0] = ' ';
    str[1] = '0';
    str[2] = 'x';
    str[3] = xm_utils_bin2c_digits[(value >> 4) & 15];
    str[4] = xm_utils_bin2c_digits[value & 15];
}

static tb_bool_t xm_utils_bin2c_dump(tb_stream_ref_t istream,
                                     tb_stream_ref_t ostream,
                                     tb_int_t        linewidth,
                                     tb_bool_t       nozeroend) {
    
    tb_bool_t first = tb_true;
    tb_byte_t data[XM_BIN2C_DATA_SIZE];
    tb_char_t line[XM_BIN2C_LINE_SIZE];
    tb_size_t linesize = 0;
    tb_size_t bytes_in_line = 0;
    tb_size_t data_pos = 0;
    tb_size_t data_size = 0;
    tb_assert_and_check_return_val(linewidth > 0 && linewidth <= XM_BIN2C_LINEWIDTH_MAX, tb_false);
    
    while (!tb_stream_beof(istream) || data_pos < data_size) {
        // read a large chunk of data if buffer is empty
        if (data_pos >= data_size) {
            tb_hong_t left = tb_stream_left(istream);
            tb_size_t to_read = (tb_size_t)tb_min(left, (tb_hong_t)XM_BIN2C_DATA_SIZE);
            tb_check_break(to_read);
            
            if (!tb_stream_bread(istream, data, to_read)) {
                break;
            }
            data_size = to_read;
            data_pos = 0;
            
            // add zero terminator at the end if needed
            if (!nozeroend && tb_stream_beof(istream)) {
                if (data_size < XM_BIN2C_DATA_SIZE) {
                    data[data_size++] = '\0';
                }
            }
        }
        
        // process bytes from buffer
        while (data_pos < data_size) {
            // check if we need a new line
            if (bytes_in_line >= (tb_size_t)linewidth) {
                // write line (tb_stream_bwrit_line will add newline automatically)
                if (tb_stream_bwrit_line(ostream, line, linesize) < 0) {
                    return tb_false;
                }
                
                linesize = 0;
                bytes_in_line = 0;
                first = tb_false;
            }
            
            // ensure we have enough space in line buffer (6 chars per byte: ", 0xXX")
            if (linesize + 6 > sizeof(line)) {
                // flush partial line if buffer is full
                if (linesize > 0) {
                    if (!tb_stream_bwrit(ostream, (tb_byte_t *)line, linesize)) {
                        return tb_false;
                    }
                    linesize = 0;
                }
            }
            
            // add separator
            if (bytes_in_line == 0) {
                if (first) {
                    line[linesize++] = ' ';
                    first = tb_false;
                } else {
                    line[linesize++] = ',';
                }
            } else {
                line[linesize++] = ',';
            }
            
            // write hex value (inline for performance)
            xm_utils_bin2c_write_hex(line + linesize, data[data_pos]);
            linesize += 5;
            bytes_in_line++;
            data_pos++;
        }
    }
    
    // flush remaining line
    if (linesize > 0) {
        // write line (tb_stream_bwrit_line will add newline automatically)
        if (tb_stream_bwrit_line(ostream, line, linesize) < 0) {
            return tb_false;
        }
    }
    
    return tb_stream_beof(istream);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* generate c/c++ code from the binary file
 *
 * local ok, errors = utils.bin2c(binaryfile, outputfile, linewidth, nozeroend)
 */
tb_int_t xm_utils_bin2c(lua_State *lua) {
    tb_assert_and_check_return_val(lua, 0);

    // get the binaryfile
    tb_char_t const *binaryfile = luaL_checkstring(lua, 1);
    tb_check_return_val(binaryfile, 0);

    // get the outputfile
    tb_char_t const *outputfile = luaL_checkstring(lua, 2);
    tb_check_return_val(outputfile, 0);

    // get line width
    tb_int_t linewidth = (tb_int_t)lua_tointeger(lua, 3);

    // no zero end?
    tb_bool_t nozeroend = (tb_bool_t)lua_toboolean(lua, 4);

    // do dump
    tb_bool_t ok = tb_false;
    tb_stream_ref_t istream = tb_stream_init_from_file(binaryfile, TB_FILE_MODE_RO);
    tb_stream_ref_t ostream = tb_stream_init_from_file(outputfile,
                                                       TB_FILE_MODE_RW | TB_FILE_MODE_CREAT | TB_FILE_MODE_TRUNC);
    do {
        if (!tb_stream_open(istream)) {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "bin2c: open %s failed", binaryfile);
            break;
        }

        if (!tb_stream_open(ostream)) {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "bin2c: open %s failed", outputfile);
            break;
        }

        if (!xm_utils_bin2c_dump(istream, ostream, linewidth, nozeroend)) {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "bin2c: dump data failed");
            break;
        }

        ok = tb_true;
        lua_pushboolean(lua, ok);

    } while (0);

    if (istream) {
        tb_stream_clos(istream);
    }
    istream = tb_null;

    if (ostream) {
        tb_stream_clos(ostream);
    }
    ostream = tb_null;

    return ok ? 1 : 2;
}
