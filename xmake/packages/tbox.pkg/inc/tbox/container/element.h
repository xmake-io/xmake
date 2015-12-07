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
 * @file        element.h
 * @ingroup     container
 *
 */
#ifndef TB_CONTAINER_ELEMENT_H
#define TB_CONTAINER_ELEMENT_H

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

/// the element ref type
typedef struct __tb_element_t* tb_element_ref_t;

/*! the element data hash function type
 *
 * @param element               the element
 * @param data                  the element data
 * @param mask                  the hash mask
 * @param index                 the hash index
 *
 * @return                      the hash value
 */
typedef tb_size_t               (*tb_element_hash_func_t)(tb_element_ref_t element, tb_cpointer_t data, tb_size_t mask, tb_size_t index);

/*! the element data compare function type
 *
 * @param element               the element
 * @param ldata                 the left-hand data
 * @param rdata                 the right-hand data
 *
 * @return                      equal: 0, 1: >, -1: <
 */
typedef tb_long_t               (*tb_element_comp_func_t)(tb_element_ref_t element, tb_cpointer_t ldata, tb_cpointer_t rdata);

/*! the element data function type
 *
 * @param element               the element
 * @param buff                 the element data address
 *
 * @return                      the element data
 */
typedef tb_pointer_t            (*tb_element_data_func_t)(tb_element_ref_t element, tb_cpointer_t buff);

/*! the element data string function type
 *
 * @param element               the element
 * @param data                  the element data
 * @param cstr                  the string buffer
 * @param maxn                  the string buffer maximum size
 *
 * @return                      the string pointer
 */
typedef tb_char_t const*        (*tb_element_cstr_func_t)(tb_element_ref_t element, tb_cpointer_t data, tb_char_t* cstr, tb_size_t maxn);

/*! the element free function type
 *
 * @param element               the element
 * @param buff                  the element buffer
 */
typedef tb_void_t               (*tb_element_free_func_t)(tb_element_ref_t element, tb_pointer_t buff);

/*! the element duplicate function type
 *
 * allocate a new element and copy the element data
 *
 * @param element               the element
 * @param buff                  the element buffer
 * @param data                  the element data
 */
typedef tb_void_t               (*tb_element_dupl_func_t)(tb_element_ref_t element, tb_pointer_t buff, tb_cpointer_t data);

/*! the element replace function type
 *
 * free the previous element data and duplicate the new data
 *
 * @param element               the element
 * @param buff                  the element buffer
 * @param data                  the element data
 */
typedef tb_void_t               (*tb_element_repl_func_t)(tb_element_ref_t element, tb_pointer_t buff, tb_cpointer_t data);

/*! the element copy function type
 *
 * only copy the element data and not allocate new element
 *
 * @param element               the element
 * @param buff                  the element buffer
 * @param data                  the element data
 */
typedef tb_void_t               (*tb_element_copy_func_t)(tb_element_ref_t element, tb_pointer_t buff, tb_cpointer_t data);

/*! the elements free function type
 *
 * free some elements
 *
 * @param element               the element
 * @param buff                  the element buffer
 * @param size                  the element count
 */
typedef tb_void_t               (*tb_element_nfree_func_t)(tb_element_ref_t element, tb_pointer_t buff, tb_size_t size);

/*! the elements duplicate function type
 *
 * duplicate some elements
 *
 * @param element               the element
 * @param buff                  the element buffer
 * @param data                  the element data
 * @param size                  the element count
 */
typedef tb_void_t               (*tb_element_ndupl_func_t)(tb_element_ref_t element, tb_pointer_t buff, tb_cpointer_t data, tb_size_t size);

/*! the elements replace function type
 *
 * replace some elements
 *
 * @param element               the element
 * @param buff                  the element buffer
 * @param data                  the element data
 * @param size                  the element count
 */
typedef tb_void_t               (*tb_element_nrepl_func_t)(tb_element_ref_t element, tb_pointer_t buff, tb_cpointer_t data, tb_size_t size);

/*! the elements copy function type
 *
 * copy some elements
 *
 * @param element               the element
 * @param buff                  the element buffer
 * @param data                  the element data
 * @param size                  the element count
 */
typedef tb_void_t               (*tb_element_ncopy_func_t)(tb_element_ref_t element, tb_pointer_t buff, tb_cpointer_t data, tb_size_t size);

/// the element type
typedef enum __tb_element_type_t
{
    TB_ELEMENT_TYPE_NULL           = 0     //!< null
,   TB_ELEMENT_TYPE_LONG           = 1     //!< long 
,   TB_ELEMENT_TYPE_SIZE           = 2     //!< size 
,   TB_ELEMENT_TYPE_UINT8          = 3     //!< uint8
,   TB_ELEMENT_TYPE_UINT16         = 4     //!< uint16
,   TB_ELEMENT_TYPE_UINT32         = 5     //!< uint32
,   TB_ELEMENT_TYPE_STR            = 6     //!< string
,   TB_ELEMENT_TYPE_PTR            = 7     //!< pointer
,   TB_ELEMENT_TYPE_MEM            = 8     //!< memory
,   TB_ELEMENT_TYPE_OBJ            = 9     //!< object
,   TB_ELEMENT_TYPE_TRUE           = 10    //!< true
,   TB_ELEMENT_TYPE_USER           = 11    //!< the user-defined type

}tb_element_type_t;

/// the element type
typedef struct __tb_element_t
{
    /// the element type
    tb_uint16_t                 type;

    /// the element flag
    tb_uint16_t                 flag;

    /// the element size
    tb_uint16_t                 size;

    /// the priv data
    tb_cpointer_t               priv;

    /// the hash function
    tb_element_hash_func_t      hash;

    /// the compare function
    tb_element_comp_func_t      comp;

    /// the data function
    tb_element_data_func_t      data;

    /// the string function 
    tb_element_cstr_func_t      cstr;

    /// the free element
    tb_element_free_func_t      free;

    /// the duplicate function
    tb_element_dupl_func_t      dupl;

    /// the replace function
    tb_element_repl_func_t      repl;

    /// the copy function
    tb_element_copy_func_t      copy; 

    /// the free elements function
    tb_element_nfree_func_t     nfree;

    /// the duplicate elements function
    tb_element_ndupl_func_t     ndupl;

    /// the replace elements function
    tb_element_nrepl_func_t     nrepl;

    /// the copy elements function
    tb_element_ncopy_func_t     ncopy;

}tb_element_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the null element, no space
 *
 * @return          the element
 */
tb_element_t        tb_element_null(tb_noarg_t);

/*! the true element, no space
 *
 * .e.g for hash data 
 *
 * @return          the element
 */
tb_element_t        tb_element_true(tb_noarg_t);

/*! the long element  
 *
 * @return          the element
 */
tb_element_t        tb_element_long(tb_noarg_t);

/*! the size element 
 *
 * @return          the element
 */
tb_element_t        tb_element_size(tb_noarg_t);

/*! the uint8 element
 *
 * @return          the element
 */
tb_element_t        tb_element_uint8(tb_noarg_t);

/*! the uint16 element for
 *
 * @return          the element
 */
tb_element_t        tb_element_uint16(tb_noarg_t);

/*! the uint32 element 
 *
 * @return          the element
 */
tb_element_t        tb_element_uint32(tb_noarg_t);

/*! the string element
 *
 * @param is_case   is case?
 *
 * @return          the element
 */
tb_element_t        tb_element_str(tb_bool_t is_case); 

/*! the pointer element
 *
 * @note if the free function have been hooked, the nfree need hook too.
 *
 * @param free      the element free function
 * @param priv      the private data of the element free function
 *
 * @return          the element
 */
tb_element_t        tb_element_ptr(tb_element_free_func_t free, tb_cpointer_t priv);

/*! the object element 
 *
 * @return          the element
 */
tb_element_t        tb_element_obj(tb_noarg_t);

/*! the memory element with the fixed space
 *
 * @param size      the element size
 * @param free      the element free function
 * @param priv      the private data of the element free function
 *
 * @return          the element
 */
tb_element_t        tb_element_mem(tb_size_t size, tb_element_free_func_t free, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

