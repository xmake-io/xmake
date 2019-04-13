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
 * @file        android.h
 * @ingroup     platform
 */
#ifndef TB_PLATFORM_ANDROID_H
#define TB_PLATFORM_ANDROID_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init the android platform
 *
 * @param jvm       the java machine pointer
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_android_init_env(JavaVM* jvm);

/// exit the android platform 
tb_void_t           tb_android_exit_env(tb_noarg_t);

/*! the java machine pointer
 *
 * @return          the java machine pointer
 */
JavaVM*             tb_android_jvm(tb_noarg_t);

#endif
