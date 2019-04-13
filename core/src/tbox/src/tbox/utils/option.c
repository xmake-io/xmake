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
 * @file        option.c
 * @ingroup     utils
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME        "option"
#define TB_TRACE_MODULE_DEBUG       (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "option.h"
#include "../libc/libc.h"
#include "../object/object.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the option impl type
typedef struct tb_option_impl_t
{
    // the command name
    tb_char_t                   name[64];

    // the command help
    tb_string_t                 help;

    // the options
    tb_option_item_t const*     opts;

    // the option list
    tb_object_ref_t             list;

}tb_option_impl_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * helper
 */
static __tb_inline__ tb_bool_t tb_option_is_bool(tb_char_t const* data)
{
    // check
    tb_assert_and_check_return_val(data, tb_false);
    return (!tb_stricmp(data, "y") || !tb_stricmp(data, "n"))? tb_true : tb_false;
}
static __tb_inline__ tb_bool_t tb_option_is_integer(tb_char_t const* data)
{
    // check
    tb_assert_and_check_return_val(data, tb_false);
    
    // init
    tb_char_t const* p = data;

    // skip '-' & '+'
    if (*p == '-' || *p == '+') p++;

    // walk
    for (; *p && tb_isdigit(*p); p++);

    // ok?
    return *p? tb_false : tb_true;
}
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
static __tb_inline__ tb_bool_t tb_option_is_float(tb_char_t const* data)
{
    // check
    tb_assert_and_check_return_val(data, tb_false);
    
    // init
    tb_char_t const* p = data;

    // walk
    for (; *p && (tb_isdigit10(*p) || *p == '.'); p++);

    // ok?
    return *p? tb_false : tb_true;
}
#endif
static __tb_inline__ tb_option_item_t const* tb_option_item_find(tb_option_item_t const* opts, tb_char_t const* lname, tb_char_t sname)
{
    // check
    tb_assert_and_check_return_val(opts, tb_null);

    // walk
    tb_bool_t                   ok = tb_false;
    tb_option_item_t const*     item = opts;
    while (item && !ok)
    {
        switch (item->mode)
        {
        case TB_OPTION_MODE_KEY:
        case TB_OPTION_MODE_KEY_VAL:
            {
                // find lname
                if (item->lname && lname && !tb_strcmp(lname, item->lname)) 
                {
                    ok = tb_true;
                    break;
                }

                // find sname
                if (item->sname && sname && (sname == item->sname) && (sname != '-')) 
                {
                    ok = tb_true;
                    break;
                }

                // next
                item++;
            }
            break;
        case TB_OPTION_MODE_VAL:
            item++;
            break;
        case TB_OPTION_MODE_MORE:
        case TB_OPTION_MODE_END:
        default:
            item = tb_null;
            break;
        }
    }

    // ok?
    return ok? item : tb_null;
}
#if 0
static __tb_inline__ tb_bool_t tb_option_check(tb_option_impl_t* impl)
{
    // check
    tb_assert_and_check_return_val(impl && impl->list && impl->opts, tb_false);

    // walk
    tb_bool_t           ok = tb_true;
    tb_option_item_t*   item = impl->opts;
    while (item && ok)
    {
        switch (item->mode)
        {
        case TB_OPTION_MODE_KEY:
        case TB_OPTION_MODE_KEY_VAL:
            item++;
            break;
        case TB_OPTION_MODE_VAL:
            {
                if (item->lname && !tb_option_find(impl, item->lname)) ok = tb_false;
                item++;
            }
            break;
        case TB_OPTION_MODE_MORE:
        case TB_OPTION_MODE_END:
        default:
            item = tb_null;
            break;
        }
    }

    // ok?
    return ok;
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_option_ref_t tb_option_init(tb_char_t const* name, tb_char_t const* help, tb_option_item_t const* opts)
{
    // check
    tb_assert_and_check_return_val(name && opts, tb_null);

    // done
    tb_bool_t           ok = tb_false;
    tb_option_impl_t*   impl = tb_null;
    do
    {
        // make option
        impl = tb_malloc0_type(tb_option_impl_t);
        tb_assert_and_check_break(impl);

        // init option
        impl->opts = opts;
        impl->list = tb_oc_dictionary_init(TB_OC_DICTIONARY_SIZE_MICRO, tb_false);
        tb_assert_and_check_break(impl->list);

        // init name
        tb_strlcpy(impl->name, name, sizeof(impl->name));

        // init help
        if (!tb_string_init(&impl->help)) break;
        if (help) tb_string_cstrcpy(&impl->help, help);

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (impl) tb_option_exit((tb_option_ref_t)impl);
        impl = tb_null;
    }

    // ok?
    return (tb_option_ref_t)impl;
}
tb_void_t tb_option_exit(tb_option_ref_t option)
{
    tb_option_impl_t* impl = (tb_option_impl_t*)option;
    if (impl)
    {
        // exit help
        tb_string_exit(&impl->help);

        // exit list
        if (impl->list) tb_object_exit(impl->list);
        impl->list = tb_null;

        // exit option
        tb_free(impl);
    }
}
tb_bool_t tb_option_find(tb_option_ref_t option, tb_char_t const* name)
{
    // check
    tb_option_impl_t* impl = (tb_option_impl_t*)option;
    tb_assert_and_check_return_val(impl && impl->list && name, tb_false);

    // find it
    return tb_oc_dictionary_value(impl->list, name)? tb_true : tb_false;
}
tb_bool_t tb_option_done(tb_option_ref_t option, tb_size_t argc, tb_char_t** argv)
{
    // check
    tb_option_impl_t* impl = (tb_option_impl_t*)option;
    tb_assert_and_check_return_val(impl && impl->list && impl->opts, tb_false);

    // walk arguments
    tb_size_t               i = 0;
    tb_size_t               more = 0;
    tb_option_item_t const* item = impl->opts;
    tb_option_item_t const* last = tb_null;
    for (i = 0; i < argc; i++)
    {
        // the argument
        tb_char_t* p = argv[i];
        tb_char_t* e = p + tb_strlen(p);
        tb_assert_and_check_return_val(p && p < e, tb_false);

        // is long key?
        if (p + 2 < e && p[0] == '-' && p[1] == '-' && tb_isalpha(p[2]))
        {
            // the key
            tb_char_t key[512] = {0};
            {
                tb_char_t* k = key;
                tb_char_t* e = key + 511;
                for (p += 2; *p && *p != '=' && k < e; p++, k++) *k = *p; 
            }

            // the val
            tb_char_t* val = (*p == '=')? (p + 1) : tb_null;

            // trace
            tb_trace_d("[lname]: %s => %s", key, val);

            // find the item
            tb_option_item_t const* find = tb_option_item_find(impl->opts, key, '\0');
            if (find)
            {
                // check key & val
                if (!val == !(find->mode == TB_OPTION_MODE_KEY_VAL))
                {
                    // has value?
                    tb_object_ref_t object = tb_null;
                    if (val)
                    {
                        // init the value object
                        switch (find->type)
                        {
                        case TB_OPTION_TYPE_CSTR:
                            object = tb_oc_string_init_from_cstr(val);
                            break;
                        case TB_OPTION_TYPE_INTEGER:
                            tb_assert_and_check_return_val(tb_option_is_integer(val), tb_false);
                            object = tb_oc_number_init_from_sint64(tb_atoll(val));
                            break;
                        case TB_OPTION_TYPE_BOOL:
                            tb_assert_and_check_return_val(tb_option_is_bool(val), tb_false);
                            object = tb_oc_boolean_init(!tb_stricmp(val, "y")? tb_true : tb_false);
                            break;
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
                        case TB_OPTION_TYPE_FLOAT:
                            tb_assert_and_check_return_val(tb_option_is_float(val), tb_false);
                            object = tb_oc_number_init_from_double(tb_atof(val));
                            break;
#endif
                        default:
                            tb_assert_and_check_return_val(0, tb_false);
                            break;
                        }
                    }
                    else
                    {
                        // check
                        tb_assert_and_check_return_val(find->type == TB_OPTION_TYPE_BOOL, tb_false);

                        // key => true
                        object = tb_oc_boolean_init(tb_true);
                    }

                    // add the value object
                    if (object)
                    {
                        tb_oc_dictionary_insert(impl->list, key, object);
                        if (tb_isalpha(find->sname)) 
                        {
                            tb_char_t ch[2] = {0};
                            ch[0] = find->sname;
                            tb_oc_dictionary_insert(impl->list, ch, object);
                            tb_object_retain(object);
                        }
                    }
                }
                else if (val)
                {
                    // print
                    tb_trace_e("%s: unrecognized option value '--%s=%s'", impl->name, key, val);

                    // next
                    continue ;
                }
                else
                {
                    // print
                    tb_trace_e("%s: no option value '--%s='", impl->name, key);

                    // next
                    continue ;
                }
            }
            else
            {
                // print
                tb_trace_e("%s: unrecognized option '--%s'", impl->name, key);

                // next
                continue ;
            }
        }
        // is short key?
        else if (p + 1 < e && p[0] == '-' && tb_isalpha(p[1]))
        {
            // the key
            tb_char_t key[512] = {0};
            {
                tb_char_t* k = key;
                tb_char_t* e = key + 511;
                for (p += 1; *p && *p != '=' && k < e; p++, k++) *k = *p; 
            }

            // the val
            tb_char_t const* val = (*p == '=')? (p + 1) : tb_null;

            // trace
            tb_trace_d("[sname]: %s => %s", key, val);

            // is short name?
            if (tb_strlen(key) != 1)
            {
                // print
                tb_trace_e("%s: unrecognized option '-%s'", impl->name, key);

                // next
                continue ;
            }

            // find the item
            tb_option_item_t const* find = tb_option_item_find(impl->opts, tb_null, key[0]);
            if (find)
            {
                // check key & val
                if (!val == !(find->mode == TB_OPTION_MODE_KEY_VAL))
                {
                    // has value?
                    tb_object_ref_t object = tb_null;
                    if (val)
                    {
                        // add value
                        switch (find->type)
                        {
                        case TB_OPTION_TYPE_CSTR:
                            object = tb_oc_string_init_from_cstr(val);
                            break;
                        case TB_OPTION_TYPE_INTEGER:
                            tb_assert_and_check_return_val(tb_option_is_integer(val), tb_false);
                            object = tb_oc_number_init_from_sint64(tb_atoll(val));
                            break;
                        case TB_OPTION_TYPE_BOOL:
                            tb_assert_and_check_return_val(tb_option_is_bool(val), tb_false);
                            object = tb_oc_boolean_init(!tb_stricmp(val, "y")? tb_true : tb_false);
                            break;
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
                        case TB_OPTION_TYPE_FLOAT:
                            tb_assert_and_check_return_val(tb_option_is_float(val), tb_false);
                            object = tb_oc_number_init_from_double(tb_atof(val));
                            break;
#endif
                        default:
                            tb_assert_and_check_return_val(0, tb_false);
                            break;
                        }
                    }
                    else
                    {
                        // check
                        tb_assert_and_check_return_val(find->type == TB_OPTION_TYPE_BOOL, tb_false);

                        // key => true
                        object = tb_oc_boolean_init(tb_true);
                    }

                    // add the value object 
                    if (object)
                    {
                        tb_oc_dictionary_insert(impl->list, key, object);
                        if (find->lname)
                        {
                            tb_oc_dictionary_insert(impl->list, find->lname, object);
                            tb_object_retain(object);
                        }
                    }
                }
                else if (val)
                {
                    // print
                    tb_trace_e("%s: unrecognized option value '--%s=%s'", impl->name, key, val);

                    // next
                    continue ;
                }
                else
                {
                    // print
                    tb_trace_e("%s: no option value '--%s='", impl->name, key);

                    // next
                    continue ;
                }
            }
            else
            {
                // print
                tb_trace_e("%s: unrecognized option '-%s'", impl->name, key);

                // next
                continue ;
            }
        }
        // is value?
        else
        {
            // trace
            tb_trace_d("[val]: %s", p);

            // find the value item 
            while (item && item->mode != TB_OPTION_MODE_VAL && item->mode != TB_OPTION_MODE_END && item->mode != TB_OPTION_MODE_MORE)
                item++;

            // has value item?
            if (item->mode == TB_OPTION_MODE_VAL)
            {
                // check
                tb_assert_and_check_return_val(item->lname, tb_false);

                // add value
                switch (item->type)
                {
                case TB_OPTION_TYPE_CSTR:
                    tb_oc_dictionary_insert(impl->list, item->lname, tb_oc_string_init_from_cstr(p));
                    break;
                case TB_OPTION_TYPE_INTEGER:
                    tb_assert_and_check_return_val(tb_option_is_integer(p), tb_false);
                    tb_oc_dictionary_insert(impl->list, item->lname, tb_oc_number_init_from_sint64(tb_atoll(p)));
                    break;
                case TB_OPTION_TYPE_BOOL:
                    tb_assert_and_check_return_val(tb_option_is_bool(p), tb_false);
                    tb_oc_dictionary_insert(impl->list, item->lname, tb_oc_boolean_init(!tb_stricmp(p, "y")? tb_true : tb_false));
                    break;
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
                case TB_OPTION_TYPE_FLOAT:
                    tb_assert_and_check_return_val(tb_option_is_float(p), tb_false);
                    tb_oc_dictionary_insert(impl->list, item->lname, tb_oc_number_init_from_double(tb_atof(p)));
                    break;
#endif
                default:
                    tb_assert_and_check_return_val(0, tb_false);
                    break;
                }

                // save last
                last = item;

                // next item
                item++;
            }
            // has more item?
            else if (item->mode == TB_OPTION_MODE_MORE && last)
            {
                // the more name
                tb_char_t name[64] = {0};
                tb_snprintf(name, 63, "more%lu", more);

                // add value
                switch (last->type)
                {
                case TB_OPTION_TYPE_CSTR:
                    tb_oc_dictionary_insert(impl->list, name, tb_oc_string_init_from_cstr(p));
                    break;
                case TB_OPTION_TYPE_INTEGER:
                    tb_assert_and_check_return_val(tb_option_is_integer(p), tb_false);
                    tb_oc_dictionary_insert(impl->list, name, tb_oc_number_init_from_sint64(tb_atoll(p)));
                    break;
                case TB_OPTION_TYPE_BOOL:
                    tb_assert_and_check_return_val(tb_option_is_bool(p), tb_false);
                    tb_oc_dictionary_insert(impl->list, name, tb_oc_boolean_init(!tb_stricmp(p, "y")? tb_true : tb_false));
                    break;
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
                case TB_OPTION_TYPE_FLOAT:
                    tb_assert_and_check_return_val(tb_option_is_float(p), tb_false);
                    tb_oc_dictionary_insert(impl->list, name, tb_oc_number_init_from_double(tb_atof(p)));
                    break;
#endif
                default:
                    tb_assert_and_check_return_val(0, tb_false);
                    break;
                }

                // next more
                more++;
            }
        }
    }

    // ok
    return tb_true;//tb_option_check(impl);
}
tb_void_t tb_option_dump(tb_option_ref_t option)
{
    // check
    tb_option_impl_t* impl = (tb_option_impl_t*)option;
    tb_assert_and_check_return(impl && impl->list);

    // dump 
    tb_object_dump(impl->list, TB_OBJECT_FORMAT_JSON);
}
tb_void_t tb_option_help(tb_option_ref_t option)
{
    // check
    tb_option_impl_t* impl = (tb_option_impl_t*)option;
    tb_assert_and_check_return(impl && impl->opts);

    // dump usage head
    tb_printf("======================================================================\n");
    tb_printf("[usage]: %s", impl->name);

    // dump usage item
    tb_bool_t               bopt = tb_false;
    tb_option_item_t const* item = impl->opts;
    while (item)
    {
        // dump options
        if (bopt && item->mode != TB_OPTION_MODE_KEY && item->mode != TB_OPTION_MODE_KEY_VAL)
        {
            tb_printf(" [options]");
            bopt = tb_false;
        }

        // dump item
        switch (item->mode)
        {
        case TB_OPTION_MODE_KEY:
        case TB_OPTION_MODE_KEY_VAL:
            {
                bopt = tb_true;
                item++;
            }
            break;
        case TB_OPTION_MODE_VAL:
            {
                tb_printf(" %s", item->lname);
                item++;
            }
            break;
        case TB_OPTION_MODE_MORE:
            tb_printf(" ...");
        case TB_OPTION_MODE_END:
        default:
            item = tb_null;
            break;
        }
    }

    // dump usage tail
    tb_printf("\n\n");

    // dump help
    if (tb_string_size(&impl->help)) 
        tb_printf("[help]:  %s\n\n", tb_string_cstr(&impl->help));

    // dump options head
    tb_printf("[options]: \n");
    for (item = impl->opts; item; )
    {
        // dump item
        tb_size_t spaces = 32;
        switch (item->mode)
        {
        case TB_OPTION_MODE_KEY:
        case TB_OPTION_MODE_KEY_VAL:
            {
                // dump spaces
                tb_printf("  "); spaces -= 3;

                // has short name?
                if (tb_isalpha(item->sname))
                {
                    // dump short name
                    tb_printf("-%c", item->sname);
                    spaces -= 2;

                    // dump long name
                    if (item->lname) 
                    {
                        tb_printf(", --%s", item->lname);
                        spaces -= 4;
                        if (tb_strlen(item->lname) <= spaces) spaces -= tb_strlen(item->lname);
                    }
                }
                // dump long name
                else if (item->lname) 
                {
                    tb_printf("    --%s", item->lname);
                    spaces -= 6;
                    if (tb_strlen(item->lname) <= spaces) spaces -= tb_strlen(item->lname);
                }

                // dump value
                if (item->mode == TB_OPTION_MODE_KEY_VAL)
                {
                    switch (item->type)
                    {
                    case TB_OPTION_TYPE_BOOL:
                        tb_printf("=BOOL"); spaces -= 5;
                        break;
                    case TB_OPTION_TYPE_CSTR:
                        tb_printf("=STRING"); spaces -= 7;
                        break;
                    case TB_OPTION_TYPE_INTEGER:
                        tb_printf("=INTEGER"); spaces -= 8;
                        break;
                    case TB_OPTION_TYPE_FLOAT:
                        tb_printf("=FLOAT"); spaces -= 6;
                        break;
                    default:
                        break;
                    }
                }

                // dump help
                if (item->help) 
                {
                    tb_char_t           line[8192] = {0};
                    tb_char_t const*    pb = item->help;
                    tb_char_t*          qb = line;
                    tb_char_t*          qe = line + 8192;
                    while (qb < qe)
                    {
                        if (*pb != '\n' && *pb) *qb++ = *pb++;
                        else
                        {
                            // strip line and next
                            *qb = '\0'; qb = line;

                            // dump spaces
                            while (spaces--) tb_printf(" ");

                            // dump help line
                            tb_printf("%s", line);

                            // reset spaces
                            spaces = 32;

                            // next or end?
                            if (*pb) 
                            {
                                // dump new line
                                tb_printf("\n");
                                pb++;
                            }
                            else break;
                        }
                    }
                }

                // dump newline
                tb_printf("\n");

                // next
                item++;
            }
            break;
        case TB_OPTION_MODE_VAL:
            item++;
            break;
        case TB_OPTION_MODE_MORE:
        case TB_OPTION_MODE_END:
        default:
            item = tb_null;
            break;
        }
    }

    // dump options tail
    tb_printf("\n\n");

    // dump values head
    tb_printf("[values]: \n");
    for (item = impl->opts; item; )
    {
        // dump item
        tb_size_t spaces = 32;
        switch (item->mode)
        {
        case TB_OPTION_MODE_KEY:
        case TB_OPTION_MODE_KEY_VAL:
            item++;
            break;
        case TB_OPTION_MODE_VAL:
            {
                // dump spaces
                tb_printf("  "); spaces -= 3;

                // dump long name
                if (item->lname) 
                {
                    tb_printf("%s", item->lname);
                    if (tb_strlen(item->lname) <= spaces) spaces -= tb_strlen(item->lname);
                }

                // dump help
                if (item->help) 
                {
                    tb_char_t           line[8192] = {0};
                    tb_char_t const*    pb = item->help;
                    tb_char_t*          qb = line;
                    tb_char_t*          qe = line + 8192;
                    while (qb < qe)
                    {
                        if (*pb != '\n' && *pb) *qb++ = *pb++;
                        else
                        {
                            // strip line and next
                            *qb = '\0'; qb = line;

                            // dump spaces
                            while (spaces--) tb_printf(" ");

                            // dump help line
                            tb_printf("%s", line);

                            // reset spaces
                            spaces = 32;

                            // next or end?
                            if (*pb) 
                            {
                                // dump new line
                                tb_printf("\n");
                                pb++;
                            }
                            else break;
                        }
                    }
                }

                // dump newline
                tb_printf("\n");

                // next
                item++;
            }
            break;
        case TB_OPTION_MODE_MORE:
            tb_printf("  ...\n");
        case TB_OPTION_MODE_END:
        default:
            item = tb_null;
            break;
        }
    }

    // dump values tail
    tb_printf("\n");
}
tb_char_t const* tb_option_item_cstr(tb_option_ref_t option, tb_char_t const* name)
{
    // check
    tb_option_impl_t* impl = (tb_option_impl_t*)option;
    tb_assert_and_check_return_val(impl && impl->list && name, tb_null);

    // the option item
    tb_object_ref_t item = tb_oc_dictionary_value(impl->list, name);
    tb_check_return_val(item, tb_null);
    tb_assert_and_check_return_val(tb_object_type(item) == TB_OBJECT_TYPE_STRING, tb_null);

    // the option item value
    return tb_oc_string_size(item)? tb_oc_string_cstr(item) : tb_null;
}
tb_bool_t tb_option_item_bool(tb_option_ref_t option, tb_char_t const* name)
{
    // check
    tb_option_impl_t* impl = (tb_option_impl_t*)option;
    tb_assert_and_check_return_val(impl && impl->list && name, tb_false);

    // the option item
    tb_object_ref_t item = tb_oc_dictionary_value(impl->list, name);
    tb_check_return_val(item, tb_false);
    tb_assert_and_check_return_val(tb_object_type(item) == TB_OBJECT_TYPE_BOOLEAN, tb_false);

    // the option item value
    return tb_oc_boolean_bool(item);
}
tb_uint8_t tb_option_item_uint8(tb_option_ref_t option, tb_char_t const* name)
{
    // check
    tb_option_impl_t* impl = (tb_option_impl_t*)option;
    tb_assert_and_check_return_val(impl && impl->list && name, 0);

    // the option item
    tb_object_ref_t item = tb_oc_dictionary_value(impl->list, name);
    tb_check_return_val(item, 0);
    tb_assert_and_check_return_val(tb_object_type(item) == TB_OBJECT_TYPE_NUMBER, 0);

    // the option item value
    return tb_oc_number_uint8(item);
}
tb_sint8_t tb_option_item_sint8(tb_option_ref_t option, tb_char_t const* name)
{
    // check
    tb_option_impl_t* impl = (tb_option_impl_t*)option;
    tb_assert_and_check_return_val(impl && impl->list && name, 0);

    // the option item
    tb_object_ref_t item = tb_oc_dictionary_value(impl->list, name);
    tb_check_return_val(item, 0);
    tb_assert_and_check_return_val(tb_object_type(item) == TB_OBJECT_TYPE_NUMBER, 0);

    // the option item value
    return tb_oc_number_sint8(item);
}
tb_uint16_t tb_option_item_uint16(tb_option_ref_t option, tb_char_t const* name)
{
    // check
    tb_option_impl_t* impl = (tb_option_impl_t*)option;
    tb_assert_and_check_return_val(impl && impl->list && name, 0);

    // the option item
    tb_object_ref_t item = tb_oc_dictionary_value(impl->list, name);
    tb_check_return_val(item, 0);
    tb_assert_and_check_return_val(tb_object_type(item) == TB_OBJECT_TYPE_NUMBER, 0);

    // the option item value
    return tb_oc_number_uint16(item);
}
tb_sint16_t tb_option_item_sint16(tb_option_ref_t option, tb_char_t const* name)
{
    // check
    tb_option_impl_t* impl = (tb_option_impl_t*)option;
    tb_assert_and_check_return_val(impl && impl->list && name, 0);

    // the option item
    tb_object_ref_t item = tb_oc_dictionary_value(impl->list, name);
    tb_check_return_val(item, 0);
    tb_assert_and_check_return_val(tb_object_type(item) == TB_OBJECT_TYPE_NUMBER, 0);

    // the option item value
    return tb_oc_number_sint16(item);
}
tb_uint32_t tb_option_item_uint32(tb_option_ref_t option, tb_char_t const* name)
{
    // check
    tb_option_impl_t* impl = (tb_option_impl_t*)option;
    tb_assert_and_check_return_val(impl && impl->list && name, 0);

    // the option item
    tb_object_ref_t item = tb_oc_dictionary_value(impl->list, name);
    tb_check_return_val(item, 0);
    tb_assert_and_check_return_val(tb_object_type(item) == TB_OBJECT_TYPE_NUMBER, 0);

    // the option item value
    return tb_oc_number_uint32(item);
}
tb_sint32_t tb_option_item_sint32(tb_option_ref_t option, tb_char_t const* name)
{
    // check
    tb_option_impl_t* impl = (tb_option_impl_t*)option;
    tb_assert_and_check_return_val(impl && impl->list && name, 0);

    // the option item
    tb_object_ref_t item = tb_oc_dictionary_value(impl->list, name);
    tb_check_return_val(item, 0);
    tb_assert_and_check_return_val(tb_object_type(item) == TB_OBJECT_TYPE_NUMBER, 0);

    // the option item value
    return tb_oc_number_sint32(item);
}
tb_uint64_t tb_option_item_uint64(tb_option_ref_t option, tb_char_t const* name)
{
    // check
    tb_option_impl_t* impl = (tb_option_impl_t*)option;
    tb_assert_and_check_return_val(impl && impl->list && name, 0);

    // the option item
    tb_object_ref_t item = tb_oc_dictionary_value(impl->list, name);
    tb_check_return_val(item, 0);
    tb_assert_and_check_return_val(tb_object_type(item) == TB_OBJECT_TYPE_NUMBER, 0);

    // the option item value
    return tb_oc_number_uint64(item);
}
tb_sint64_t tb_option_item_sint64(tb_option_ref_t option, tb_char_t const* name)
{
    // check
    tb_option_impl_t* impl = (tb_option_impl_t*)option;
    tb_assert_and_check_return_val(impl && impl->list && name, 0);

    // the option item
    tb_object_ref_t item = tb_oc_dictionary_value(impl->list, name);
    tb_check_return_val(item, 0);
    tb_assert_and_check_return_val(tb_object_type(item) == TB_OBJECT_TYPE_NUMBER, 0);

    // the option item value
    return tb_oc_number_sint64(item);
}
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
tb_float_t tb_option_item_float(tb_option_ref_t option, tb_char_t const* name)
{
    // check
    tb_option_impl_t* impl = (tb_option_impl_t*)option;
    tb_assert_and_check_return_val(impl && impl->list && name, 0);

    // the option item
    tb_object_ref_t item = tb_oc_dictionary_value(impl->list, name);
    tb_check_return_val(item, 0);
    tb_assert_and_check_return_val(tb_object_type(item) == TB_OBJECT_TYPE_NUMBER, 0);

    // the option item value
    return tb_oc_number_float(item);
}
tb_double_t tb_option_item_double(tb_option_ref_t option, tb_char_t const* name)
{
    // check
    tb_option_impl_t* impl = (tb_option_impl_t*)option;
    tb_assert_and_check_return_val(impl && impl->list && name, 0);

    // the option item
    tb_object_ref_t item = tb_oc_dictionary_value(impl->list, name);
    tb_check_return_val(item, 0);
    tb_assert_and_check_return_val(tb_object_type(item) == TB_OBJECT_TYPE_NUMBER, 0);

    // the option item value
    return tb_oc_number_double(item);
}
#endif
