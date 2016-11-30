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
 * Copyright (C) 2009 - 2017, ruki All rights reserved.
 *
 * @author      ruki
 * @file        data.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_DEPRECATED_DATA_H
#define TB_OBJECT_DEPRECATED_DATA_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
#define tb_object_data_init_from_url        tb_oc_data_init_from_url
#define tb_object_data_init_from_data       tb_oc_data_init_from_data
#define tb_object_data_init_from_buffer     tb_oc_data_init_from_buffer
#define tb_object_data_getp                 tb_oc_data_getp
#define tb_object_data_setp                 tb_oc_data_setp
#define tb_object_data_size                 tb_oc_data_size
#define tb_object_data_buffer               tb_oc_data_buffer
#define tb_object_data_writ_to_url          tb_oc_data_writ_to_url

#endif

