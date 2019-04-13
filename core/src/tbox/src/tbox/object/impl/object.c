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
 * @file        object.c
 * @ingroup     object
 *
 */
 
/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME        "object"
#define TB_TRACE_MODULE_DEBUG       (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "object.h"
#include "reader/reader.h"
#include "writer/writer.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_object_init_env()
{
    // register reader
    if (!tb_oc_reader_set(TB_OBJECT_FORMAT_BIN, tb_oc_bin_reader())) return tb_false;
    if (!tb_oc_reader_set(TB_OBJECT_FORMAT_JSON, tb_oc_json_reader())) return tb_false;
    if (!tb_oc_reader_set(TB_OBJECT_FORMAT_BPLIST, tb_oc_bplist_reader())) return tb_false;
 
    // register writer
    if (!tb_oc_writer_set(TB_OBJECT_FORMAT_BIN, tb_oc_bin_writer())) return tb_false;
    if (!tb_oc_writer_set(TB_OBJECT_FORMAT_JSON, tb_oc_json_writer())) return tb_false;
    if (!tb_oc_writer_set(TB_OBJECT_FORMAT_BPLIST, tb_oc_bplist_writer())) return tb_false;

    // register reader and writer for xml
#ifdef TB_CONFIG_MODULE_HAVE_XML
    if (!tb_oc_reader_set(TB_OBJECT_FORMAT_XML, tb_oc_xml_reader())) return tb_false;
    if (!tb_oc_writer_set(TB_OBJECT_FORMAT_XML, tb_oc_xml_writer())) return tb_false;
    if (!tb_oc_reader_set(TB_OBJECT_FORMAT_XPLIST, tb_oc_xplist_reader())) return tb_false;
    if (!tb_oc_writer_set(TB_OBJECT_FORMAT_XPLIST, tb_oc_xplist_writer())) return tb_false;
#endif

    // ok
    return tb_true;
}
tb_void_t tb_object_exit_env()
{
    // remove reader
    tb_oc_reader_remove(TB_OBJECT_FORMAT_BIN);
    tb_oc_reader_remove(TB_OBJECT_FORMAT_JSON);
    tb_oc_reader_remove(TB_OBJECT_FORMAT_BPLIST);

    // remove writer
    tb_oc_writer_remove(TB_OBJECT_FORMAT_BIN);
    tb_oc_writer_remove(TB_OBJECT_FORMAT_JSON);
    tb_oc_writer_remove(TB_OBJECT_FORMAT_BPLIST);

    // remove reader and writer for xml
#ifdef TB_CONFIG_MODULE_HAVE_XML
    tb_oc_reader_remove(TB_OBJECT_FORMAT_XML);
    tb_oc_writer_remove(TB_OBJECT_FORMAT_XML);
    tb_oc_reader_remove(TB_OBJECT_FORMAT_XPLIST);
    tb_oc_writer_remove(TB_OBJECT_FORMAT_XPLIST);
#endif
}

