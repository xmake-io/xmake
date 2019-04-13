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
 * @file        zip.c
 * @ingroup     zip
 *
 */
/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "zip.h"
#include "gzip.h"
#include "zlib.h"
#include "zlibraw.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

tb_zip_ref_t tb_zip_init(tb_size_t algo, tb_size_t action)
{
    // table
    static tb_zip_ref_t (*s_init[])(tb_size_t action) =
    {
        tb_null
#ifdef TB_CONFIG_PACKAGE_HAVE_ZLIB
    ,   tb_zip_zlibraw_init
    ,   tb_zip_zlib_init
    ,   tb_zip_gzip_init
#else
    ,   tb_null
    ,   tb_null
    ,   tb_null
#endif
    };
    tb_assert_and_check_return_val(algo < tb_arrayn(s_init) && s_init[algo], tb_null);

    // init
    return s_init[algo](action);
}
tb_void_t tb_zip_exit(tb_zip_ref_t zip)
{
    // check
    tb_assert_and_check_return(zip);

    // table
    static tb_void_t (*s_exit[])(tb_zip_ref_t zip) =
    {
        tb_null
#ifdef TB_CONFIG_PACKAGE_HAVE_ZLIB
    ,   tb_zip_zlibraw_exit
    ,   tb_zip_zlib_exit
    ,   tb_zip_gzip_exit
#else
    ,   tb_null
    ,   tb_null
    ,   tb_null
#endif
    };
    tb_assert_and_check_return(zip->algo < tb_arrayn(s_exit) && s_exit[zip->algo]);

    // exit
    s_exit[zip->algo](zip);
}
tb_long_t tb_zip_spak(tb_zip_ref_t zip, tb_static_stream_ref_t ist, tb_static_stream_ref_t ost, tb_long_t sync)
{
    // check
    tb_assert_and_check_return_val(zip && zip->spak && ist && ost, -1);

    // spank it
    return zip->spak(zip, ist, ost, sync);
}

