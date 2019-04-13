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
 * @file        semaphore.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include <errno.h>
#include <sys/types.h>
#include <sys/sem.h>
#include <sys/ipc.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_semaphore_ref_t tb_semaphore_init(tb_size_t init)
{
    // init semaphore
    tb_long_t h = semget((key_t)IPC_PRIVATE, 1, IPC_CREAT | IPC_EXCL | 0666);
    tb_assert_and_check_return_val(h >= 0 || errno == EEXIST, tb_null);

    // exists?
    if (errno == EEXIST)
    {
        h = semget((key_t)IPC_PRIVATE, 1, 0);
        tb_assert_and_check_return_val(h >= 0, tb_null);
    }

    // init value
#if 0
    union semun opts;
    opts.val = init;
#else
    union semun_u 
    {
        tb_int_t            val;
        struct semid_ds*    buf;
        tb_uint16_t*        array;
        struct seminfo*     __buf;
        tb_pointer_t        __pad;

    }opts;
    opts.val = init;
#endif
    if (semctl(h, 0, SETVAL, opts) < 0)
    {
        tb_semaphore_exit((tb_semaphore_ref_t)(h + 1));
        return tb_null;
    }

    // ok
    return (tb_semaphore_ref_t)(h + 1);
}
tb_void_t tb_semaphore_exit(tb_semaphore_ref_t semaphore)
{
    // check
    tb_long_t h = (tb_long_t)semaphore - 1;
    tb_assert_and_check_return(semaphore);

    // remove semaphore
    tb_long_t r = semctl(h, 0, IPC_RMID);
    tb_assert(r != -1);
}
tb_bool_t tb_semaphore_post(tb_semaphore_ref_t semaphore, tb_size_t post)
{
    // check
    tb_long_t h = (tb_long_t)semaphore - 1;
    tb_assert_and_check_return_val(semaphore && post, tb_false);

    // post
    while (post--)
    {
        // init
        struct sembuf sb;
        sb.sem_num = 0;
        sb.sem_op = 1;
        sb.sem_flg = SEM_UNDO;

        // post it
        if (semop(h, &sb, 1) < 0) return tb_false;
    }

    // ok
    return tb_true;
}
tb_long_t tb_semaphore_value(tb_semaphore_ref_t semaphore)
{
    // check
    tb_long_t h = (tb_long_t)semaphore - 1;
    tb_assert_and_check_return_val(semaphore, -1);

    // get value
    return semctl(h, 0, GETVAL, 0);
}
tb_long_t tb_semaphore_wait(tb_semaphore_ref_t semaphore, tb_long_t timeout)
{
    // check
    tb_long_t h = (tb_long_t)semaphore - 1;
    tb_assert_and_check_return_val(semaphore, -1);

    // init time
    struct timeval t = {0};
    if (timeout > 0)
    {
        t.tv_sec = timeout / 1000;
        t.tv_usec = (timeout % 1000) * 1000;
    }

    // init
    struct sembuf sb;
    sb.sem_num = 0;
    sb.sem_op = -1;
    sb.sem_flg = SEM_UNDO;

    // wait semaphore
    tb_long_t r = semtimedop(h, &sb, 1, timeout >= 0? &t : tb_null);

    // ok?
    tb_check_return_val(r, 1);

    // timeout?
    tb_check_return_val(errno != EAGAIN, 0);

    // error
    return -1;
}
