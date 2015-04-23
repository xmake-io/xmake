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
 * @file        prefix.h
 *
 */
#ifndef TB_PLATFORM_WINDOWS_INTERFACE_PREFIX_H
#define TB_PLATFORM_WINDOWS_INTERFACE_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"
#include "../../atomic.h"
#include "../../dynamic.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#define TB_INTERFACE_LOAD(module_name, interface_name) \
    do \
    { \
        module_name->interface_name = (tb_##module_name##_##interface_name##_t)GetProcAddress((HMODULE)module, #interface_name); \
        \
    } while (0)

#endif
