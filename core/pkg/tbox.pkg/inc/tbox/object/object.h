/*!The Treasure Box Library
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * Copyright (C) 2009 - 2017, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        object.h
 * @defgroup    object
 *
 */
#ifndef TB_OBJECT_H
#define TB_OBJECT_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "null.h"
#include "data.h"
#include "date.h"
#include "array.h"
#include "string.h"
#include "number.h"
#include "boolean.h"
#include "dictionary.h"
#ifdef TB_CONFIG_API_HAVE_DEPRECATED
#   include "deprecated/deprecated.h"
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init object
 *
 * @param object    the object
 * @param flag      the object flag
 * @param type      the object type
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_object_init(tb_object_ref_t object, tb_size_t flag, tb_size_t type);

/*! decrease the object reference count, will exit it if --refn == 0
 *
 * @param object    the object
 *
 * @note the reference count must be one
 */
tb_void_t           tb_object_exit(tb_object_ref_t object);

/*! clear object
 *
 * @param object    the object
 */
tb_void_t           tb_object_clear(tb_object_ref_t object);

/*! set the object private data
 *
 * @param object    the object
 * @param priv      the private data
 *
 */
tb_void_t           tb_object_setp(tb_object_ref_t object, tb_cpointer_t priv);

/*! get the object private data
 *
 * @param object    the object
 *
 * @return          the private data
 */
tb_cpointer_t       tb_object_getp(tb_object_ref_t object);

/*! read object
 *
 * @param stream    the stream
 *
 * @return          the object
 */
tb_object_ref_t     tb_object_read(tb_stream_ref_t stream);

/*! read object from url
 *
 * @param url       the url
 *
 * @return          the object
 */
tb_object_ref_t     tb_object_read_from_url(tb_char_t const* url);

/*! read object from data
 *
 * @param data      the data
 * @param size      the size
 *
 * @return          the object
 */
tb_object_ref_t     tb_object_read_from_data(tb_byte_t const* data, tb_size_t size);

/*! writ object
 *
 * @param object    the object
 * @param stream    the stream
 * @param format    the object format
 *
 * @return          the writed size, failed: -1
 */
tb_long_t           tb_object_writ(tb_object_ref_t object, tb_stream_ref_t stream, tb_size_t format);

/*! writ object to url
 *
 * @param object    the object
 * @param url       the url
 * @param format    the format
 *
 * @return          the writed size, failed: -1
 */
tb_long_t           tb_object_writ_to_url(tb_object_ref_t object, tb_char_t const* url, tb_size_t format);

/*! writ object to data
 *
 * @param object    the object
 * @param data      the data
 * @param size      the size
 * @param format    the format
 *
 * @return          the writed size, failed: -1
 */
tb_long_t           tb_object_writ_to_data(tb_object_ref_t object, tb_byte_t* data, tb_size_t size, tb_size_t format);

/*! copy object
 *
 * @param object    the object
 *
 * @return          the object copy
 */
tb_object_ref_t     tb_object_copy(tb_object_ref_t object);

/*! the object type
 *
 * @param object    the object
 *
 * @return          the object type
 */
tb_size_t           tb_object_type(tb_object_ref_t object);

/*! the object data
 *
 * @param object    the object
 * @param format    the format
 *
 * @return          the data object
 */
tb_object_ref_t     tb_object_data(tb_object_ref_t object, tb_size_t format);

/*! seek to the object for the gived path
 *
 * <pre>
 *
    file:
    {
        "string":       "hello world!"
    ,   "com.xxx.xxx":  "hello world"
    ,   "integer":      31415926
    ,   "array":
        [
            "hello world!"
        ,   31415926
        ,   3.1415926
        ,   false
        ,   true
        ,   { "string": "hello world!" }
        ]
    ,   "macro":        "$.array[2]"
    ,   "macro2":       "$.com\\\\.xxx\\\\.xxx"
    ,   "macro3":       "$.macro"
    ,   "macro4":       "$.array"
    }

    path:
        1. ".string"               : hello world!
        2. ".array[1]"             : 31415926
        3. ".array[5].string"      : hello world!
        4. ".com\\.xxx\\.xxx"      : hello world
        5. ".macro"                : 3.1415926
        6. ".macro2"               : hello world
        7. ".macro3"               : 3.1415926
        8. ".macro4[0]"            : "hello world!"

 * 
 * </pre>
 *
 * @param object    the object
 * @param path      the object path
 * @param bmacro    enable macro(like "$.path")? 
 *
 * <code>
 * tb_object_ref_t object = tb_object_seek(root, ".array[5].string", tb_false);
 * if (object)
 * {
 *      tb_trace_d("%s", tb_oc_string_cstr(object));
 * }
 * <endcode>
 *
 *
 * @return          the object
 */
tb_object_ref_t     tb_object_seek(tb_object_ref_t object, tb_char_t const* path, tb_bool_t bmacro);

/*! dump the object
 *
 * @param object    the object
 * @param format    the format, support: .xml, .xplist, .json
 *
 * @return          the object
 */
tb_object_ref_t     tb_object_dump(tb_object_ref_t object, tb_size_t format);

/*! the object reference count
 *
 * @param object    the object
 *
 * @return          the object reference count
 */
tb_size_t           tb_object_refn(tb_object_ref_t object);

/*! retain object and increase the object reference count
 *
 * @param object    the object
 */
tb_void_t           tb_object_retain(tb_object_ref_t object);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

