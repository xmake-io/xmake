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
 * @file        gzip.h
 * @ingroup     zip
 *
 */
#ifndef TB_ZIP_GZIP_H
#define TB_ZIP_GZIP_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#ifdef TB_CONFIG_PACKAGE_HAVE_ZLIB
#   include "zlib/zlib.h"
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the gzip zip type
typedef struct __tb_zip_gzip_t
{
    // the zip base
    tb_zip_t        base;

    // the zstream
#ifdef TB_CONFIG_PACKAGE_HAVE_ZLIB
    z_stream        zstream;
#endif

}tb_zip_gzip_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/* init gzip 
 *
 * @param action    the action
 *
 * @return          the zip
 */
tb_zip_ref_t        tb_zip_gzip_init(tb_size_t action);

/* exit gzip
 *
 * @param zip       the zip
 */
tb_void_t           tb_zip_gzip_exit(tb_zip_ref_t zip);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

