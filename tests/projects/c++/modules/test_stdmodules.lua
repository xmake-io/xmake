inherit("test_base")

CLANG_MIN_VER = "19"
GCC_MIN_VER = "15"
MSVC_MIN_VER = "14.35"

function main(_)
    local clang_options = {stdmodule = true, compiler = "clang", version = CLANG_MIN_VER}
    local gcc_options = {stdmodule = true, compiler = "gcc", version = GCC_MIN_VER}
    -- latest mingw gcc 15.1 is broken
    --  error: F:/msys64/mingw64/include/c++/15.1.0/shared_mutex:105:3: error: 'int std::__glibcxx_rwlock_timedrdlock(pthread_rwlock_t*, const timespec*)' exposes TU-local entity 'int pthread_rwlock_timedrdlock(pthread_rwlock_t*, const timespec*)'
    --   105 |   __glibcxx_rwlock_timedrdlock (pthread_rwlock_t *__rwlock,
    --       |   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- In file included from F:/msys64/mingw64/include/c++/15.1.0/x86_64-w64-mingw32/bits/gthr-default.h:35,
    --                  from F:/msys64/mingw64/include/c++/15.1.0/x86_64-w64-mingw32/bits/gthr.h:157,
    --                  from F:/msys64/mingw64/include/c++/15.1.0/ext/atomicity.h:37,
    --                  from F:/msys64/mingw64/include/c++/15.1.0/bits/ios_base.h:41,
    --                  from F:/msys64/mingw64/include/c++/15.1.0/streambuf:45,
    --                  from F:/msys64/mingw64/include/c++/15.1.0/bits/streambuf_iterator.h:37,
    --                  from F:/msys64/mingw64/include/c++/15.1.0/iterator:68,
    --                  from F:/msys64/mingw64/include/c++/15.1.0/x86_64-w64-mingw32/bits/stdc++.h:56:
    -- F:/msys64/mingw64/include/pthread.h:296:28: note: 'int pthread_rwlock_timedrdlock(pthread_rwlock_t*, const timespec*)' declared with internal linkage
    --   296 | WINPTHREAD_RWLOCK_DECL int pthread_rwlock_timedrdlock(pthread_rwlock_t *l, const struct timespec *ts)
    --       |                            ^~~~~~~~~~~~~~~~~~~~~~~~~~
    -- F:/msys64/mingw64/include/c++/15.1.0/shared_mutex:115:3: error: 'int std::__glibcxx_rwlock_timedwrlock(pthread_rwlock_t*, const timespec*)' exposes TU-local entity 'int pthread_rwlock_timedwrlock(pthread_rwlock_t*, const timespec*)'
    --   115 |   __glibcxx_rwlock_timedwrlock (pthread_rwlock_t *__rwlock,   local gcc_options = {stdmodule = true, compiler = "gcc", version = GCC_MIN_VER}
    if is_subhost("msys") then
        gcc_options = nil
    end
    local msvc_options = {stdmodule = true, version = MSVC_MIN_VER}
    run_tests(clang_options, gcc_options, msvc_options)
end
