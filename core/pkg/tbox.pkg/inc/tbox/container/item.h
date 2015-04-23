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
 * @file        item.h
 * @ingroup     container
 *
 */
#ifndef TB_CONTAINER_ITEM_H
#define TB_CONTAINER_ITEM_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

struct __tb_item_func_t;

/*! the item data hash func type
 *
 * @param func                  the item func
 * @param data                  the item data
 * @param mask                  the hash mask
 * @param index                 the hash index
 *
 * @return                      the hash value
 */
typedef tb_size_t               (*tb_item_func_hash_t)(struct __tb_item_func_t* func, tb_cpointer_t data, tb_size_t mask, tb_size_t index);

/*! the item data compare func type
 *
 * @param func                  the item func
 * @param ldata                 the left-hand data
 * @param rdata                 the right-hand data
 *
 * @return                      equal: 0, 1: >, -1: <
 */
typedef tb_long_t               (*tb_item_func_comp_t)(struct __tb_item_func_t* func, tb_cpointer_t ldata, tb_cpointer_t rdata);

/*! the item data func type
 *
 * @param func                  the item func
 * @param buff                 the item data address
 *
 * @return                      the item data
 */
typedef tb_pointer_t            (*tb_item_func_data_t)(struct __tb_item_func_t* func, tb_cpointer_t buff);

/*! the item data string func type
 *
 * @param func                  the item func
 * @param data                  the item data
 * @param cstr                  the string buffer
 * @param maxn                  the string buffer maximum size
 *
 * @return                      the string pointer
 */
typedef tb_char_t const*        (*tb_item_func_cstr_t)(struct __tb_item_func_t* func, tb_cpointer_t data, tb_char_t* cstr, tb_size_t maxn);

/*! the item data load func type
 *
 * load data to the item from the stream
 *
 * @param func                  the item func
 * @param buff                  the item buffer
 * @param stream                the stream
 *
 * @return                      tb_true or tb_false
 */
typedef tb_bool_t               (*tb_item_func_load_t)(struct __tb_item_func_t* func, tb_pointer_t buff, tb_stream_ref_t stream);

/*! the item data save func type
 *
 * save data to the stream
 *
 * @param func                  the item func
 * @param data                  the item data
 * @param stream                the stream
 *
 * @return                      tb_true or tb_false
 */
typedef tb_bool_t               (*tb_item_func_save_t)(struct __tb_item_func_t* func, tb_cpointer_t data, tb_stream_ref_t stream);

/*! the item free func type
 *
 * @param func                  the item func
 * @param buff                  the item buffer
 */
typedef tb_void_t               (*tb_item_func_free_t)(struct __tb_item_func_t* func, tb_pointer_t buff);

/*! the item duplicate func type
 *
 * allocate a new item and copy the item data
 *
 * @param func                  the item func
 * @param buff                  the item buffer
 * @param data                  the item data
 */
typedef tb_void_t               (*tb_item_func_dupl_t)(struct __tb_item_func_t* func, tb_pointer_t buff, tb_cpointer_t data);

/*! the item replace func type
 *
 * free the previous item data and duplicate the new data
 *
 * @param func                  the item func
 * @param buff                  the item buffer
 * @param data                  the item data
 */
typedef tb_void_t               (*tb_item_func_repl_t)(struct __tb_item_func_t* func, tb_pointer_t buff, tb_cpointer_t data);

/*! the item copy func type
 *
 * only copy the item data and not allocate new item
 *
 * @param func                  the item func
 * @param buff                 the item data address
 * @param data                  the item data
 */
typedef tb_void_t               (*tb_item_func_copy_t)(struct __tb_item_func_t* func, tb_pointer_t buff, tb_cpointer_t data);

/*! the items free func type
 *
 * free some items
 *
 * @param func                  the item func
 * @param buff                  the item buffer
 * @param size                  the item count
 */
typedef tb_void_t               (*tb_item_func_nfree_t)(struct __tb_item_func_t* func, tb_pointer_t buff, tb_size_t size);

/*! the items duplicate func type
 *
 * duplicate some items
 *
 * @param func                  the item func
 * @param buff                  the item buffer
 * @param data                  the item data
 * @param size                  the item count
 */
typedef tb_void_t               (*tb_item_func_ndupl_t)(struct __tb_item_func_t* func, tb_pointer_t buff, tb_cpointer_t data, tb_size_t size);

/*! the items replace func type
 *
 * replace some items
 *
 * @param func                  the item func
 * @param buff                  the item buffer
 * @param data                  the item data
 * @param size                  the item count
 */
typedef tb_void_t               (*tb_item_func_nrepl_t)(struct __tb_item_func_t* func, tb_pointer_t buff, tb_cpointer_t data, tb_size_t size);

/*! the items copy func type
 *
 * copy some items
 *
 * @param func                  the item func
 * @param buff                  the item buffer
 * @param data                  the item data
 * @param size                  the item count
 */
typedef tb_void_t               (*tb_item_func_ncopy_t)(struct __tb_item_func_t* func, tb_pointer_t buff, tb_cpointer_t data, tb_size_t size);

/// the item type
typedef enum __tb_item_type_t
{
    TB_ITEM_TYPE_NULL           = 0     //!< null
,   TB_ITEM_TYPE_LONG           = 1     //!< integer for tb_long_t
,   TB_ITEM_TYPE_SIZE           = 2     //!< integer for tb_size_t
,   TB_ITEM_TYPE_UINT8          = 3     //!< integer for tb_uint8_t
,   TB_ITEM_TYPE_UINT16         = 4     //!< integer for tb_uint16_t
,   TB_ITEM_TYPE_UINT32         = 5     //!< integer for tb_uint32_t
,   TB_ITEM_TYPE_STR            = 6     //!< string
,   TB_ITEM_TYPE_PTR            = 7     //!< pointer
,   TB_ITEM_TYPE_MEM            = 8     //!< memory
,   TB_ITEM_TYPE_OBJ            = 9     //!< object
,   TB_ITEM_TYPE_TRUE           = 10    //!< true
,   TB_ITEM_TYPE_USER           = 11    //!< the user defined type

}tb_item_type_t;

/// the item func type
typedef struct __tb_item_func_t
{
    /// the item type
    tb_uint16_t             type;

    /// the item flag
    tb_uint16_t             flag;

    /// the item size
    tb_uint16_t             size;

    /// the priv data
    tb_cpointer_t           priv;

    /// the hash func
    tb_item_func_hash_t     hash;

    /// the compare func
    tb_item_func_comp_t     comp;

    /// the data func
    tb_item_func_data_t     data;

    /// the string func 
    tb_item_func_cstr_t     cstr;

    /// the free item func
    tb_item_func_free_t     free;

    /// the duplicate func
    tb_item_func_dupl_t     dupl;

    /// the replace func
    tb_item_func_repl_t     repl;

    /// the copy func
    tb_item_func_copy_t     copy; 

    /// the free items func
    tb_item_func_nfree_t    nfree;

    /// the duplicate items func
    tb_item_func_ndupl_t    ndupl;

    /// the replace items func
    tb_item_func_nrepl_t    nrepl;

    /// the copy items func
    tb_item_func_ncopy_t    ncopy;

}tb_item_func_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the null item function, no space
 *
 * @return          the item func
 */
tb_item_func_t      tb_item_func_null(tb_noarg_t);

/*! the true item function, no space
 *
 * .e.g for hash data 
 *
 * @return          the item func
 */
tb_item_func_t      tb_item_func_true(tb_noarg_t);

/*! the integer item function for tb_long_t 
 *
 * @return          the item func
 */
tb_item_func_t      tb_item_func_long(tb_noarg_t);

/*! the integer item function for tb_size_t
 *
 * @return          the item func
 */
tb_item_func_t      tb_item_func_size(tb_noarg_t);

/*! the integer item function for tb_uint8_t
 *
 * @return          the item func
 */
tb_item_func_t      tb_item_func_uint8(tb_noarg_t);

/*! the integer item function for tb_uint16_t
 *
 * @return          the item func
 */
tb_item_func_t      tb_item_func_uint16(tb_noarg_t);

/*! the integer item function for tb_uint32_t
 *
 * @return          the item func
 */
tb_item_func_t      tb_item_func_uint32(tb_noarg_t);

/*! the string item function
 *
 * @param bcase     is case?
 *
 * @return          the item func
 */
tb_item_func_t      tb_item_func_str(tb_bool_t bcase); 

/*! the pointer item function
 *
 * @note if the free func have been hooked, the nfree need hook too.
 *
 * @param free      the item free func
 * @param priv      the private data of the item free func
 *
 * @return          the item func
 */
tb_item_func_t      tb_item_func_ptr(tb_item_func_free_t free, tb_cpointer_t priv);

/*! the object item function 
 *
 * @return          the item func
 */
tb_item_func_t      tb_item_func_obj(tb_noarg_t);

/*! the internal fixed memory item function
 *
 * storing it in the internal item of the container directly for saving memory
 *
 * @param size      the item size
 * @param free      the item free func
 * @param priv      the private data of the item free func
 *
 * @return          the item func
 */
tb_item_func_t      tb_item_func_mem(tb_size_t size, tb_item_func_free_t free, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

