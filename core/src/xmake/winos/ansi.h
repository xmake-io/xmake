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
 * Copyright (C) 2015 - 2019, TBOOX Open Source Group.
 *
 * @author      OpportunityLiu
 * @file        ansi.h
 *
 */
#ifndef XM_WINOS_ANSI_H
#define XM_WINOS_ANSI_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

#ifdef TB_CONFIG_OS_WINDOWS
tb_size_t xm_wcstoutf8(tb_char_t *s1, tb_wchar_t const *s2, tb_size_t n);
tb_size_t xm_utf8towcs(tb_wchar_t *s1, tb_char_t const *s2, tb_size_t n);
tb_size_t xm_mbstoutf8(tb_char_t *s1, tb_char_t const *s2, tb_size_t n, tb_int_t mbs_cp);
tb_size_t xm_utf8tombs(tb_char_t *s1, tb_char_t const *s2, tb_size_t n, tb_int_t mbs_cp);
#endif

#endif
