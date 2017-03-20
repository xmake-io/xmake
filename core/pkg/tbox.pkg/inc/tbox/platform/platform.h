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
 * @file        platform.h
 * @defgroup    platform
 *
 */
#ifndef TB_PLATFORM_H
#define TB_PLATFORM_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "page.h"
#include "path.h"
#include "file.h"
#include "time.h"
#include "mutex.h"
#include "event.h"
#include "timer.h"
#include "print.h"
#include "ltimer.h"
#include "socket.h"
#include "thread.h"
#include "atomic.h"
#include "memory.h"
#include "poller.h"
#include "context.h"
#include "ifaddrs.h"
#include "barrier.h"
#include "dynamic.h"
#include "process.h"
#include "addrinfo.h"
#include "spinlock.h"
#include "atomic64.h"
#include "hostname.h"
#include "processor.h"
#include "semaphore.h"
#include "backtrace.h"
#include "directory.h"
#include "exception.h"
#include "cache_time.h"
#include "environment.h"
#include "thread_pool.h"
#include "thread_local.h"
#ifdef TB_CONFIG_API_HAVE_DEPRECATED
#   include "deprecated/deprecated.h"
#endif

#endif
