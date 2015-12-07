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
 * @file        android.h
 * @ingroup     platform
 */
#ifndef TB_PLATFORM_LINUX_ANDROID_H
#define TB_PLATFORM_LINUX_ANDROID_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init the android platform
 *
 * @param jenv      the jni environment pointer
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_android_init(JNIEnv* jenv);

/// exit the android platform 
tb_void_t           tb_android_exit(tb_noarg_t);

/*! the jni environment pointer
 *
 * @return          the environment pointer
 */
JNIEnv*             tb_android_jenv(tb_noarg_t);

#endif
