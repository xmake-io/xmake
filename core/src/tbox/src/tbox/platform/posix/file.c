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
 * Copyright (C) 2009 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        file.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../file.h"
#include "../path.h"
#include "../directory.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/uio.h>
#include <unistd.h>
#include <errno.h>
#ifdef TB_CONFIG_POSIX_HAVE_COPYFILE
#   include <copyfile.h>
#endif
#ifdef TB_CONFIG_POSIX_HAVE_SENDFILE
#   include <sys/sendfile.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_file_ref_t tb_file_init(tb_char_t const* path, tb_size_t mode)
{
    // check
    tb_assert_and_check_return_val(path, tb_null);

    // the full path
    tb_char_t full[TB_PATH_MAXN];
    path = tb_path_absolute(path, full, TB_PATH_MAXN);
    tb_assert_and_check_return_val(path, tb_null);

    // flags
    tb_size_t flags = 0;
    if (mode & TB_FILE_MODE_RO) flags |= O_RDONLY;
    else if (mode & TB_FILE_MODE_WO) flags |= O_WRONLY;
    else if (mode & TB_FILE_MODE_RW) flags |= O_RDWR;

    if (mode & TB_FILE_MODE_CREAT) flags |= O_CREAT;
    if (mode & TB_FILE_MODE_APPEND) flags |= O_APPEND;
    if (mode & TB_FILE_MODE_TRUNC) flags |= O_TRUNC;

    // dma mode, no cache
#ifdef TB_CONFIG_OS_LINUX
    if (mode & TB_FILE_MODE_DIRECT) flags |= O_DIRECT;
#endif

    // noblock
    flags |= O_NONBLOCK;

    // modes
    tb_size_t modes = 0;
    if (mode & TB_FILE_MODE_CREAT) 
    {
        // 0644: -rw-r--r-- 
        modes = S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH;
    }

    // open it, @note need absolute path
    tb_long_t fd = open(path, flags, modes);
    if (fd < 0 && (mode & TB_FILE_MODE_CREAT))
    {
#ifndef TB_CONFIG_MICRO_ENABLE
        // open it again after creating the file directory
        tb_char_t dir[TB_PATH_MAXN];
        if (tb_directory_create(tb_path_directory(path, dir, sizeof(dir))))
            fd = open(path, flags, modes);
#endif
    }
 
    // trace
    tb_trace_d("open: %p", tb_fd2file(fd));

    // ok?
    return tb_fd2file(fd);
}
tb_bool_t tb_file_exit(tb_file_ref_t file)
{
    // check
    tb_assert_and_check_return_val(file, tb_false);

    // trace
    tb_trace_d("clos: %p", file);

    // close it
    tb_bool_t ok = !close(tb_file2fd(file))? tb_true : tb_false;
    
    // failed?
    if (!ok)
    {
        // trace
        tb_trace_e("close: %p failed, errno: %d", file, errno);
    }

    // ok?
    return ok;
}
tb_long_t tb_file_read(tb_file_ref_t file, tb_byte_t* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(file, -1);

    // read it
    return read(tb_file2fd(file), data, size);
}
tb_long_t tb_file_writ(tb_file_ref_t file, tb_byte_t const* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(file, -1);

    // writ it
    return write(tb_file2fd(file), data, size);
}
tb_bool_t tb_file_sync(tb_file_ref_t file)
{
    // check
    tb_assert_and_check_return_val(file, tb_false);

    // sync
#ifdef TB_CONFIG_POSIX_HAVE_FDATASYNC
    return !fdatasync(tb_file2fd(file))? tb_true : tb_false;
#else
    return !fsync(tb_file2fd(file))? tb_true : tb_false;
#endif
}
tb_hong_t tb_file_seek(tb_file_ref_t file, tb_hong_t offset, tb_size_t mode)
{
    // check
    tb_assert_and_check_return_val(file, -1);

    // seek
    return lseek(tb_file2fd(file), offset, mode);
}
tb_hong_t tb_file_offset(tb_file_ref_t file)
{
    // check
    tb_assert_and_check_return_val(file, -1);

    // the offset
    return tb_file_seek(file, (tb_hong_t)0, TB_FILE_SEEK_CUR);
}
tb_hize_t tb_file_size(tb_file_ref_t file)
{
    // check
    tb_assert_and_check_return_val(file, 0);

    // the file size
    tb_hize_t size = 0;
    struct stat st = {0};
    if (!fstat(tb_file2fd(file), &st))
        size = st.st_size;

    // ok?
    return size;
}
tb_bool_t tb_file_info(tb_char_t const* path, tb_file_info_t* info)
{
    // check
    tb_assert_and_check_return_val(path, tb_false);

    // the full path (need translate "~/")
    tb_char_t full[TB_PATH_MAXN];
    path = tb_path_absolute(path, full, TB_PATH_MAXN);
    tb_assert_and_check_return_val(path, tb_false);

    // exists?
    tb_check_return_val(!access(path, F_OK), tb_false);

    // get info
    if (info)
    {
        // init info
        tb_memset(info, 0, sizeof(tb_file_info_t));

        // get stat
#ifdef TB_CONFIG_POSIX_HAVE_STAT64
        struct stat64 st = {0};
        if (!stat64(path, &st))
#else
        struct stat st = {0};
        if (!stat(path, &st))
#endif
        {
            // file type
            if (S_ISDIR(st.st_mode)) info->type = TB_FILE_TYPE_DIRECTORY;
            else info->type = TB_FILE_TYPE_FILE;

            // file size
            info->size = st.st_size >= 0? (tb_hize_t)st.st_size : 0;

            // the last access time
            info->atime = (tb_time_t)st.st_atime;

            // the last modify time
            info->mtime = (tb_time_t)st.st_mtime;
        }
    }

    // ok
    return tb_true;
}
#ifndef TB_CONFIG_MICRO_ENABLE
tb_long_t tb_file_pread(tb_file_ref_t file, tb_byte_t* data, tb_size_t size, tb_hize_t offset)
{
    // check
    tb_assert_and_check_return_val(file, -1);

    // read it
#ifdef TB_CONFIG_POSIX_HAVE_PREAD64
    return pread64(tb_file2fd(file), data, (size_t)size, offset);
#else
    return pread(tb_file2fd(file), data, (size_t)size, offset);
#endif
}
tb_long_t tb_file_pwrit(tb_file_ref_t file, tb_byte_t const* data, tb_size_t size, tb_hize_t offset)
{
    // check
    tb_assert_and_check_return_val(file, -1);

    // writ it
#ifdef TB_CONFIG_POSIX_HAVE_PWRITE64
    return pwrite64(tb_file2fd(file), data, (size_t)size, offset);
#else
    return pwrite(tb_file2fd(file), data, (size_t)size, offset);
#endif
}
tb_long_t tb_file_readv(tb_file_ref_t file, tb_iovec_t const* list, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(file && list && size, -1);

    // check iovec
    tb_assert_static(sizeof(tb_iovec_t) == sizeof(struct iovec));
    tb_assert(tb_memberof_eq(tb_iovec_t, data, struct iovec, iov_base));
    tb_assert(tb_memberof_eq(tb_iovec_t, size, struct iovec, iov_len));

    // read it
    return readv(tb_file2fd(file), (struct iovec const*)list, size);
}
tb_long_t tb_file_writv(tb_file_ref_t file, tb_iovec_t const* list, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(file && list && size, -1);

    // check iovec
    tb_assert_static(sizeof(tb_iovec_t) == sizeof(struct iovec));
    tb_assert(tb_memberof_eq(tb_iovec_t, data, struct iovec, iov_base));
    tb_assert(tb_memberof_eq(tb_iovec_t, size, struct iovec, iov_len));

    // writ it
    return writev(tb_file2fd(file), (struct iovec const*)list, size);
}
tb_hong_t tb_file_writf(tb_file_ref_t file, tb_file_ref_t ifile, tb_hize_t offset, tb_hize_t size)
{
    // check
    tb_assert_and_check_return_val(file && ifile && size, -1);

#ifdef TB_CONFIG_POSIX_HAVE_SENDFILE

    // writ it
    off_t       seek = offset;
    tb_hong_t   real = sendfile(tb_file2fd(file), tb_file2fd(ifile), &seek, (size_t)size);

    // ok?
    if (real >= 0) return real;

    // continue?
    if (errno == EINTR || errno == EAGAIN) return 0;

    // error
    return -1;

#else

    // read data
    tb_byte_t data[8192];
    tb_long_t read = tb_file_pread(ifile, data, sizeof(data), offset);
    tb_check_return_val(read > 0, read);

    // writ data
    tb_size_t writ = 0;
    while (writ < read)
    {
        tb_long_t real = tb_file_writ(file, data + writ, read - writ);
        if (real > 0) writ += real;
        else break;
    }

    // ok?
    return writ == read? writ : -1;
#endif
}
tb_long_t tb_file_preadv(tb_file_ref_t file, tb_iovec_t const* list, tb_size_t size, tb_hize_t offset)
{
    // check
    tb_assert_and_check_return_val(file && list && size, -1);

    // check iovec
    tb_assert_static(sizeof(tb_iovec_t) == sizeof(struct iovec));
    tb_assert(tb_memberof_eq(tb_iovec_t, data, struct iovec, iov_base));
    tb_assert(tb_memberof_eq(tb_iovec_t, size, struct iovec, iov_len));

    // read it
#ifdef TB_CONFIG_POSIX_HAVE_PREADV
    return preadv(tb_file2fd(file), (struct iovec const*)list, size, offset);
#else
 
    // FIXME: lock it

    // save offset
    tb_hong_t current = tb_file_offset(file);
    tb_assert_and_check_return_val(current >= 0, -1);

    // seek it
    if (current != offset && tb_file_seek(file, offset, TB_FILE_SEEK_BEG) != offset) return -1;

    // read it
    tb_long_t real = tb_file_readv(file, list, size);

    // restore offset
    if (current != offset && tb_file_seek(file, current, TB_FILE_SEEK_BEG) != current) return -1;

    // ok
    return real;
#endif
}
tb_long_t tb_file_pwritv(tb_file_ref_t file, tb_iovec_t const* list, tb_size_t size, tb_hize_t offset)
{
    // check
    tb_assert_and_check_return_val(file && list && size, -1);

    // check iovec
    tb_assert_static(sizeof(tb_iovec_t) == sizeof(struct iovec));
    tb_assert(tb_memberof_eq(tb_iovec_t, data, struct iovec, iov_base));
    tb_assert(tb_memberof_eq(tb_iovec_t, size, struct iovec, iov_len));

    // writ it
#ifdef TB_CONFIG_POSIX_HAVE_PWRITEV
    return pwritev(tb_file2fd(file), (struct iovec const*)list, size, offset);
#else

    // FIXME: lock it

    // save offset
    tb_hong_t current = tb_file_offset(file);
    tb_assert_and_check_return_val(current >= 0, -1);

    // seek it
    if (current != offset && tb_file_seek(file, offset, TB_FILE_SEEK_BEG) != offset) return -1;

    // writ it
    tb_long_t real = tb_file_writv(file, list, size);

    // restore offset
    if (current != offset && tb_file_seek(file, current, TB_FILE_SEEK_BEG) != current) return -1;

    // ok
    return real;
#endif
}
tb_bool_t tb_file_copy(tb_char_t const* path, tb_char_t const* dest)
{
    // check
    tb_assert_and_check_return_val(path && dest, tb_false);

#ifdef TB_CONFIG_POSIX_HAVE_COPYFILE

    // the full path
    tb_char_t full0[TB_PATH_MAXN];
    path = tb_path_absolute(path, full0, TB_PATH_MAXN);
    tb_assert_and_check_return_val(path, tb_false);

    // the dest path
    tb_char_t full1[TB_PATH_MAXN];
    dest = tb_path_absolute(dest, full1, TB_PATH_MAXN);
    tb_assert_and_check_return_val(dest, tb_false);

    // attempt to copy it directly
    if (!copyfile(path, dest, 0, COPYFILE_ALL)) return tb_true;
    else
    {
        // attempt to copy it again after creating directory
        tb_char_t dir[TB_PATH_MAXN];
        if (tb_directory_create(tb_path_directory(dest, dir, sizeof(dir))))
            return !copyfile(path, dest, 0, COPYFILE_ALL);
    }

    // failed
    return tb_false;
#else
    tb_int_t    ifd = -1;
    tb_int_t    ofd = -1;
    tb_bool_t   ok = tb_false;
    do
    {
        // get the absolute source path
        tb_char_t data[8192];
        path = tb_path_absolute(path, data, sizeof(data));
        tb_assert_and_check_break(path);

        // get stat.st_mode first
#ifdef TB_CONFIG_POSIX_HAVE_STAT64
        struct stat64 st = {0};
        if (stat64(path, &st)) break;
#else
        struct stat st = {0};
        if (stat(path, &st)) break;
#endif

        // open source file
        ifd = open(path, O_RDONLY);
        tb_check_break(ifd >= 0);

        // get the absolute source path
        dest = tb_path_absolute(dest, data, sizeof(data));
        tb_assert_and_check_break(dest);

        // open destinate file and copy file mode
        ofd = open(dest, O_RDWR | O_CREAT | O_TRUNC, st.st_mode & (S_IRWXU | S_IRWXG | S_IRWXO));
        if (ofd < 0)
        {
            // attempt to open it again after creating directory
            tb_char_t dir[TB_PATH_MAXN];
            if (tb_directory_create(tb_path_directory(dest, dir, sizeof(dir))))
                ofd = open(dest, O_RDWR | O_CREAT | O_TRUNC, st.st_mode & (S_IRWXU | S_IRWXG | S_IRWXO));
        }
        tb_check_break(ofd >= 0);

        // get file size
        tb_hize_t size = tb_file_size(tb_fd2file(ifd));

        // init write size
        tb_hize_t writ = 0; 
       
        // attempt to copy file using `sendfile`
#ifdef TB_CONFIG_POSIX_HAVE_SENDFILE
        while (writ < size)
        {
            off_t seek = writ;
            tb_hong_t real = sendfile(ofd, ifd, &seek, (size_t)(size - writ));
            if (real > 0) writ += real;
            else break;
        }

        /* attempt to copy file directly if sendfile failed 
         *
         * sendfile() supports regular file only after "since Linux 2.6.33".
         */
        if (writ != size) 
        {
            lseek(ifd, 0, SEEK_SET);
            lseek(ofd, 0, SEEK_SET);
        }
        else
        {
            ok = tb_true;
            break;
        }
#endif

        // copy file using `read` and `write`
        writ = 0;
        while (writ < size)
        {
            // read some data
            tb_int_t real = read(ifd, data, (size_t)tb_min(size - writ, sizeof(data)));
            if (real > 0)
            {
                real = write(ofd, data, real);
                if (real > 0) writ += real;
                else break;
            }
            else break;
        }

        // ok?
        ok = (writ == size);

    } while (0);

    // close source file
    if (ifd >= 0) close(ifd);
    ifd = -1;

    // close destinate file
    if (ofd >= 0) close(ofd);
    ofd = -1;

    // ok?
    return ok;
#endif
}
tb_bool_t tb_file_create(tb_char_t const* path)
{
    // check
    tb_assert_and_check_return_val(path, tb_false);

    // make it
    tb_file_ref_t file = tb_file_init(path, TB_FILE_MODE_CREAT | TB_FILE_MODE_WO | TB_FILE_MODE_TRUNC);
    if (file) tb_file_exit(file);

    // ok?
    return file? tb_true : tb_false;
}
tb_bool_t tb_file_remove(tb_char_t const* path)
{
    // check
    tb_assert_and_check_return_val(path, tb_false);

    // the full path
    tb_char_t full[TB_PATH_MAXN];
    path = tb_path_absolute(path, full, TB_PATH_MAXN);
    tb_assert_and_check_return_val(path, tb_false);

    // remove it
    return !remove(path)? tb_true : tb_false;
}
tb_bool_t tb_file_rename(tb_char_t const* path, tb_char_t const* dest)
{
    // check
    tb_assert_and_check_return_val(path && dest, tb_false);

    // the full path
    tb_char_t full0[TB_PATH_MAXN];
    path = tb_path_absolute(path, full0, TB_PATH_MAXN);
    tb_assert_and_check_return_val(path, tb_false);

    // the dest path
    tb_char_t full1[TB_PATH_MAXN];
    dest = tb_path_absolute(dest, full1, TB_PATH_MAXN);
    tb_assert_and_check_return_val(dest, tb_false);

    // attempt to rename it directly
    if (!rename(path, dest)) return tb_true;
    else
    {
        // attempt to rename it again after creating directory
        tb_char_t dir[TB_PATH_MAXN];
        if (tb_directory_create(tb_path_directory(dest, dir, sizeof(dir))))
            return !rename(path, dest);
    }
    return tb_false;
}
tb_bool_t tb_file_link(tb_char_t const* path, tb_char_t const* dest)
{
    // check
    tb_assert_and_check_return_val(path && dest, tb_false);

    // the full path
    tb_char_t full0[TB_PATH_MAXN];
    path = tb_path_absolute(path, full0, TB_PATH_MAXN);
    tb_assert_and_check_return_val(path, tb_false);

    // the dest path
    tb_char_t full1[TB_PATH_MAXN];
    dest = tb_path_absolute(dest, full1, TB_PATH_MAXN);
    tb_assert_and_check_return_val(dest, tb_false);

    // attempt to link it directly
    if (!symlink(path, dest)) return tb_true;
    else
    {
        // attempt to link it again after creating directory
        tb_char_t dir[TB_PATH_MAXN];
        if (tb_directory_create(tb_path_directory(dest, dir, sizeof(dir))))
            return !symlink(path, dest);
    }
    return tb_false;
}
#endif
