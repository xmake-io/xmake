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
 * @path        path.c
 * @ingroup     platform
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "path"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "path.h"
#include "directory.h"
#include "../libc/libc.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the path separator
#ifdef TB_CONFIG_OS_WINDOWS
#   define TB_PATH_SEPARATOR            '\\'
#else
#   define TB_PATH_SEPARATOR            '/'
#endif

// is path separator?
#ifdef TB_CONFIG_OS_WINDOWS
#   define tb_path_is_separator(c)      ('/' == (c) || '\\' == (c))
#else
#   define tb_path_is_separator(c)      ('/' == (c))
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#ifndef TB_CONFIG_MICRO_ENABLE
tb_size_t tb_path_translate(tb_char_t* path, tb_size_t size, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(path, 0);

    // file://?
    tb_char_t* p = path;
    if (!tb_strnicmp(p, "file:", 5)) p += 5;
    // is user directory?
    else if (path[0] == '~')
    {
        // get the home directory
        tb_char_t home[TB_PATH_MAXN];
        tb_size_t home_size = tb_directory_home(home, sizeof(home) - 1);
        tb_assert_and_check_return_val(home_size, 0);

        // check the path space
        tb_size_t path_size = size? size : tb_strlen(path);
        tb_assert_and_check_return_val(home_size + path_size - 1 < maxn, 0);

        // move the path and ensure the enough space for the home directory
        tb_memmov(path + home_size, path + 1, path_size - 1);

        // copy the home directory 
        tb_memcpy(path, home, home_size);
        path[home_size + path_size - 1] = '\0';
    }

    // remove repeat separator
    tb_char_t*  q = path;
    tb_size_t   repeat = 0;
    for (; *p; p++)
    {
        if (tb_path_is_separator(*p))
        {
            // save the separator if not exists
            if (!repeat) *q++ = TB_PATH_SEPARATOR;

            // repeat it
            repeat++;
        }
        else 
        {
            // save character
            *q++ = *p;

            // clear repeat
            repeat = 0;
        }
    }

    // remove the tail separator and not root: '/'
    if (q > path + 1 && *(q - 1) == TB_PATH_SEPARATOR) q--;

    // end
    *q = '\0';

    // is windows path? 
    if (q > path + 1 && tb_isalpha(path[0]) && path[1] == ':')
    {
        // get the upper drive prefix
        path[0] = tb_toupper(path[0]);

        // root? patch "x:" => "x:\"
        if (q == path + 2 && q + 1 < path + maxn) 
        {
            *q++ = TB_PATH_SEPARATOR;
            *q = '\0';
        }
    }

    // trace
    tb_trace_d("translate: %s", path);

    // ok
    return q - path;
}
#endif
tb_bool_t tb_path_is_absolute(tb_char_t const* path)
{
    // check
    tb_assert_and_check_return_val(path, tb_false);

    // is absolute?
#ifdef TB_CONFIG_OS_WINDOWS
    return (    path[0] == '~'
            ||  (tb_isalpha(path[0]) && path[1] == ':'));
#else
    return (    path[0] == '/'
            ||  path[0] == '\\'
            ||  path[0] == '~'
            ||  !tb_strnicmp(path, "file:", 5));
#endif
}
tb_char_t const* tb_path_absolute(tb_char_t const* path, tb_char_t* data, tb_size_t maxn)
{
    return tb_path_absolute_to(tb_null, path, data, maxn);
}
tb_char_t const* tb_path_absolute_to(tb_char_t const* root, tb_char_t const* path, tb_char_t* data, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(path && data && maxn, tb_null);

    // trace
    tb_trace_d("path: %s", path);

#ifdef TB_CONFIG_MICRO_ENABLE

    // the path is absolute?
    if (tb_path_is_absolute(path)) return path;

    // trace
    tb_trace_e("absolute to %s to %s failed!", path, root);
    return tb_null;
#else

    // the path is absolute?
    if (tb_path_is_absolute(path))
    {
        // copy it
        tb_strlcpy(data, path, maxn);

        // translate it
        return tb_path_translate(data, 0, maxn)? data : tb_null;
    }

    // get the root directory
    tb_size_t size = 0;
    if (root)
    {
        // copy it
        size = tb_strlcpy(data, root, maxn);
        tb_assert_and_check_return_val(size < maxn, tb_null);
    }
    else
    {
        // get the current directory
        if (!(size = tb_directory_current(data, maxn))) return tb_null;
    }

    // translate the root directory
    size = tb_path_translate(data, size, maxn);

    // trace
    tb_trace_d("root: %s, size: %lu", data, size);

    // is windows path? skip the drive prefix
    tb_char_t* absolute = data;
    if (size > 2 && tb_isalpha(absolute[0]) && absolute[1] == ':' && absolute[2] == TB_PATH_SEPARATOR)
    {
        // skip it
        absolute    += 2;
        size        -= 2;
    }

    // path => data
    tb_char_t const*    p = path;
    tb_char_t const*    t = p;
    tb_char_t*          q = absolute + size;
    tb_char_t const*    e = absolute + maxn - 1;
    while (1)
    {
        if (tb_path_is_separator(*p) || !*p)
        {
            // the item size
            tb_size_t n = p - t;

            // ..? remove item
            if (n == 2 && t[0] == '.' && t[1] == '.')
            {
                // find the last separator
                for (; q > absolute && *q != TB_PATH_SEPARATOR; q--) ;

                // strip it
                *q = '\0';
            }
            // .? continue it
            else if (n == 1 && t[0] == '.') ;
            // append item
            else if (n && q + 1 + n < e)
            {
                // append separator
                *q++ = TB_PATH_SEPARATOR;

                // append item
                tb_strncpy(q, t, n);
                q += n;

                // strip it
                *q = '\0';
            }
            // empty item? remove repeat
            else if (!n) ;
            // too small?
            else 
            {
                // trace
                tb_trace_e("the data path is too small for %s", path);
                return tb_null;
            }

            // break
            tb_check_break(*p);

            // next
            t = p + 1;
        }

        // next
        p++;
    }

    // end
    if (q > absolute) *q = '\0';
    // root?
    else
    {
        *q++ = TB_PATH_SEPARATOR;
        *q = '\0';
    }

    // trace    
    tb_trace_d("absolute: %s", data);
    
    // ok?
    return data;
#endif
}
#ifndef TB_CONFIG_MICRO_ENABLE
tb_char_t const* tb_path_relative(tb_char_t const* path, tb_char_t* data, tb_size_t maxn)
{
    return tb_path_relative_to(tb_null, path, data, maxn);
}
tb_char_t const* tb_path_relative_to(tb_char_t const* root, tb_char_t const* path, tb_char_t* data, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(path && data && maxn, tb_null);

    // trace
    tb_trace_d("path: %s", path);

    // the root is the current and the path is absolute? return path directly
    if (!root && !tb_path_is_absolute(path))
    {
        // copy it
        tb_strlcpy(data, path, maxn);

        // translate it
        return tb_path_translate(data, 0, maxn)? data : tb_null;
    }

    // get the absolute path
    tb_size_t path_size = 0;
    tb_char_t path_absolute[TB_PATH_MAXN];
    tb_size_t path_maxn = sizeof(path_absolute);
    path        = tb_path_absolute(path, path_absolute, path_maxn);
    path_size   = tb_strlen(path);
    tb_assert_and_check_return_val(path && path_size && path_size < path_maxn, tb_null);

    // trace
    tb_trace_d("path_absolute: %s", path);

    // get the absolute root
    tb_size_t root_size = 0;
    tb_char_t root_absolute[TB_PATH_MAXN];
    tb_size_t root_maxn = sizeof(root_absolute);
    if (root) 
    {
        // get the absolute root
        root        = tb_path_absolute(root, root_absolute, root_maxn);
        root_size   = tb_strlen(root);
    }
    else
    {
        // get the current directory
        if (!(root_size = tb_directory_current(root_absolute, root_maxn))) return tb_null;

        // translate it
        if (!(root_size = tb_path_translate(root_absolute, root_size, root_maxn))) return tb_null;
        root = root_absolute;
    }
    tb_assert_and_check_return_val(root && root_size && root_size < root_maxn, tb_null);

    // trace
    tb_trace_d("root_absolute: %s", root);

    // same directory? return "."
    if (path_size == root_size && !tb_strncmp(path, root, root_size)) 
    {
        // check
        tb_assert_and_check_return_val(maxn >= 2, ".");

        // return "."
        data[0] = '.';
        data[1] = '\0';
        return data;
    }

    // append separator
    if (path_size + 1 < path_maxn)
    {
        path_absolute[path_size++] = TB_PATH_SEPARATOR;
        path_absolute[path_size] = '\0';
    }
    if (root_size + 1 < root_maxn) 
    {
        root_absolute[root_size++] = TB_PATH_SEPARATOR;
        root_absolute[root_size] = '\0';
    }

    // trace
    tb_trace_d("path: %s, root: %s", path_absolute, root_absolute);

    // find the common leading directory
    tb_char_t const*    p = path_absolute;
    tb_char_t const*    q = root_absolute;
    tb_long_t           last = -1;
    for (; *p && *q && *p == *q; q++, p++)
    {
        // save the last separator
        if (*p == TB_PATH_SEPARATOR) last = q - root_absolute;
    }

    // is different directory or outside the windows drive root? using the absolute path
    if (last <= 0 || (last == 2 && root_absolute[1] == ':' && root_size > 3))
    {
        // trace
        tb_trace_d("no common root: %d", last);

        // the path size
        tb_size_t size = tb_min(path_size - 1, maxn);

        // copy it
        tb_strncpy(data, path, size);
        data[size] = '\0';
    }
    // exists same root?
    else
    {
        // count the remaining levels in root
        tb_size_t count = 0;
        tb_char_t const* l = root_absolute + last + 1;
        for (; *l; l++)
        {
            if (*l == TB_PATH_SEPARATOR) count++;
        }

        // append "../" or "..\\"
        tb_char_t* d = data;
        tb_char_t* e = data + maxn;
        while (count--)
        {
            if (d + 3 < e)
            {
                d[0] = '.';
                d[1] = '.';
                d[2] = TB_PATH_SEPARATOR;
                d += 3;
            }
        }

        // append the left path
        l = path_absolute + last + 1;
        while (*l && d < e) *d++ = *l++;

        // remove the last separator
        if (d > data) d--;

        // end
        *d = '\0';
    }

    // trace    
    tb_trace_d("relative: %s", data);
    
    // ok?
    return data;
}
#endif
tb_char_t const* tb_path_directory(tb_char_t const* path, tb_char_t* data, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(path && data && maxn, tb_null);

    // find the last path separator
    tb_size_t n = tb_strlen(path);
    tb_char_t const* p = path + n - 1;
    while (p >= path && *p)
    {
        // found
        if (tb_path_is_separator(*p))
        {
            n = p - path;
            if (n < maxn)
            {
                tb_strncpy(data, path, n);
                data[n] = '\0';
                return data;
            }
            else return tb_null;
        }
        p--;
    }

    // end
    return ".";
}
