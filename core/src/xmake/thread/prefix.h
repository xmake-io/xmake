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
 * @file        prefix.h
 *
 */
#ifndef XM_THREAD_PREFIX_H
#define XM_THREAD_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the thread type
typedef struct __xm_thread_t {
    tb_thread_ref_t handle;
    tb_string_t callback;
    tb_string_t callinfo;
} xm_thread_t;

// the thread value kind
typedef enum __xm_thread_value_kind_e {
    XM_THREAD_VALUE_NIL  = 0,
    XM_THREAD_VALUE_BOOL = 1,
    XM_THREAD_VALUE_INT  = 2,
    XM_THREAD_VALUE_NUM  = 3,
    XM_THREAD_VALUE_STR  = 4
} xm_thread_value_kind_e;

// the thread value type
typedef struct __xm_thread_value_t {
    tb_uint32_t kind : 3;
    tb_uint32_t size : 29;
    union {
        tb_char_t *string;
        tb_bool_t boolean;
        lua_Integer integer;
        lua_Number number;
    } u;
} xm_thread_value_t;

// the thread event type
typedef struct __xm_thread_event_t {
    tb_event_ref_t handle;
    tb_atomic_t refn;
} xm_thread_event_t;

// the thread mutex type
typedef struct __xm_thread_mutex_t {
    tb_mutex_ref_t handle;
    tb_atomic_t refn;
} xm_thread_mutex_t;

// the thread semaphore type
typedef struct __xm_thread_semaphore_t {
    tb_semaphore_ref_t handle;
    tb_atomic_t refn;
} xm_thread_semaphore_t;

// the thread queue type
typedef struct __xm_thread_queue_t {
    tb_queue_ref_t handle;
    tb_atomic_t refn;
} xm_thread_queue_t;

// the thread sharedata type
typedef struct __xm_thread_sharedata_t {
    xm_thread_value_t value;
    tb_buffer_t buffer;
    tb_atomic_t refn;
} xm_thread_sharedata_t;

// get the thread event from arguments
static __tb_inline__ xm_thread_event_t *xm_thread_event_get(lua_State *lua, tb_int_t index) {
    xm_thread_event_t *thread_event = tb_null;
    if (xm_lua_isinteger(lua, index)) {
        thread_event = (xm_thread_event_t *)(tb_size_t)(tb_long_t)lua_tointeger(lua, index);
    } else if (xm_lua_ispointer(lua, index)) {
        thread_event = (xm_thread_event_t *)xm_lua_topointer(lua, index);
    }
    return thread_event;
}

// get the thread mutex from arguments
static __tb_inline__ xm_thread_mutex_t *xm_thread_mutex_get(lua_State *lua, tb_int_t index) {
    xm_thread_mutex_t *thread_mutex = tb_null;
    if (xm_lua_isinteger(lua, index)) {
        thread_mutex = (xm_thread_mutex_t *)(tb_size_t)(tb_long_t)lua_tointeger(lua, index);
    } else if (xm_lua_ispointer(lua, index)) {
        thread_mutex = (xm_thread_mutex_t *)xm_lua_topointer(lua, index);
    }
    return thread_mutex;
}

// get the thread semaphore from arguments
static __tb_inline__ xm_thread_semaphore_t *xm_thread_semaphore_get(lua_State *lua, tb_int_t index) {
    xm_thread_semaphore_t *thread_semaphore = tb_null;
    if (xm_lua_isinteger(lua, index)) {
        thread_semaphore = (xm_thread_semaphore_t *)(tb_size_t)(tb_long_t)lua_tointeger(lua, index);
    } else if (xm_lua_ispointer(lua, index)) {
        thread_semaphore = (xm_thread_semaphore_t *)xm_lua_topointer(lua, index);
    }
    return thread_semaphore;
}

// get the thread queue from arguments
static __tb_inline__ xm_thread_queue_t *xm_thread_queue_get(lua_State *lua, tb_int_t index) {
    xm_thread_queue_t *thread_queue = tb_null;
    if (xm_lua_isinteger(lua, index)) {
        thread_queue = (xm_thread_queue_t *)(tb_size_t)(tb_long_t)lua_tointeger(lua, index);
    } else if (xm_lua_ispointer(lua, index)) {
        thread_queue = (xm_thread_queue_t *)xm_lua_topointer(lua, index);
    }
    return thread_queue;
}

// get the thread sharedata from arguments
static __tb_inline__ xm_thread_sharedata_t *xm_thread_sharedata_get(lua_State *lua, tb_int_t index) {
    xm_thread_sharedata_t *thread_sharedata = tb_null;
    if (xm_lua_isinteger(lua, index)) {
        thread_sharedata = (xm_thread_sharedata_t *)(tb_size_t)(tb_long_t)lua_tointeger(lua, index);
    } else if (xm_lua_ispointer(lua, index)) {
        thread_sharedata = (xm_thread_sharedata_t *)xm_lua_topointer(lua, index);
    }
    return thread_sharedata;
}

#endif
