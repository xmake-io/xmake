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
 * @file        zlibraw.h
 * @ingroup     zip
 *
 */
#ifndef TB_ZIP_ZLIBRAW_H
#define TB_ZIP_ZLIBRAW_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#ifdef TB_CONFIG_PACKAGE_HAVE_ZLIB
#   include <zlib.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the zlibraw zip type
typedef struct __tb_zip_zlibraw_t
{
    // the zip base
    tb_zip_t        base;

    // the zstream
#ifdef TB_CONFIG_PACKAGE_HAVE_ZLIB
    z_stream        zstream;
#endif

}tb_zip_zlibraw_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/* init zlibraw 
 *
 * @param action    the action
 *
 * @return          the zip
 */
tb_zip_ref_t        tb_zip_zlibraw_init(tb_size_t action);

/* exit zlibraw
 *
 * @param zip       the zip
 */
tb_void_t           tb_zip_zlibraw_exit(tb_zip_ref_t zip);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

