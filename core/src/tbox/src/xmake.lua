-- option: demo
option("demo")
    set_default(false)
    set_showmenu(true)
    set_category("option")
    set_description("Enable or disable the demo module")

-- option: micro
option("micro")
    set_default(false)
    set_showmenu(true)
    set_category("option")
    set_description("Compile micro core library for the embed system.")
    add_defines_h("$(prefix)_MICRO_ENABLE")

-- option: small
option("small")
    set_default(true)
    set_showmenu(true)
    set_category("option")
    set_description("Enable the small compile mode and disable all modules.")

-- option: wchar
option("wchar")
    add_ctypes("wchar_t")
    add_defines_h("$(prefix)_TYPE_HAVE_WCHAR")

-- option: float
option("float")
    set_default(true)
    set_showmenu(true)
    set_category("option")
    set_description("Enable or disable the float type")
    add_deps("micro")
    add_defines_h("$(prefix)_TYPE_HAVE_FLOAT")
    after_check(function (option)
        if option:dep("micro"):enabled() then
            option:enable(false)
        end
    end)

-- option: info
option("info")
    set_default(true)
    set_showmenu(true)
    set_category("option")
    set_description("Enable or disable to get some info, .e.g version ..")
    add_deps("small", "micro")
    add_defines_h("$(prefix)_INFO_HAVE_VERSION")
    add_defines_h("$(prefix)_INFO_TRACE_MORE")
    after_check(function (option)
        if option:dep("small"):enabled() or option:dep("micro"):enabled() then
            option:enable(false)
        end
    end)

-- option: exception
option("exception")
    set_default(false)
    set_showmenu(true)
    set_category("option")
    set_description("Enable or disable the exception.")
    add_defines_h("$(prefix)_EXCEPTION_ENABLE")

-- option: deprecated
option("deprecated")
    set_default(false)
    set_showmenu(true)
    set_category("option")
    set_description("Enable or disable the deprecated interfaces.")
    add_defines_h("$(prefix)_API_HAVE_DEPRECATED")

-- add modules
for _, name in ipairs({"xml", "zip", "hash", "regex", "object", "charset", "database", "coroutine"}) do
    option(name)
        set_default(true)
        set_showmenu(true)
        set_category("module")
        set_description(format("The %s module", name))
        add_deps("small", "micro")
        add_defines_h(format("$(prefix)_MODULE_HAVE_%s", name:upper()))
        after_check(function (option)
            if (name ~= "hash" and name ~= "charset") and (option:dep("small"):enabled() or option:dep("micro"):enabled()) then
                option:enable(false)
            end
        end)
end

-- the base package
option("base")
    set_default(true)
    if is_os("windows") then add_links("ws2_32") 
    elseif is_os("android") then add_links("m", "c") 
    else add_links("pthread", "dl", "m", "c") end

-- add packages
for _, name in ipairs({"zlib", "mysql", "sqlite3", "openssl", "polarssl", "mbedtls", "pcre2", "pcre"}) do
    option(name)
        set_showmenu(true)
        set_category("package")
        set_description(format("The %s package", name))
        add_deps("small", "micro")
        add_defines_h(format("$(prefix)_PACKAGE_HAVE_%s", name:upper()))
        before_check(function (option)
            import("lib.detect.find_package")
            if not option:dep("small"):enabled() and not option:dep("micro"):enabled() then
                option:add(find_package(name, {packagedirs = path.join(os.projectdir(), "pkg")}))
            end
        end)
end

-- check interfaces
function check_interfaces()

    -- add the interfaces for libc
    add_cfuncs("libc", nil,         {"string.h", "stdlib.h"},           "memcpy",
                                                                        "memset",
                                                                        "memmove",
                                                                        "memcmp",
                                                                        "memmem",
                                                                        "strcat",
                                                                        "strncat",
                                                                        "strcpy",
                                                                        "strncpy",
                                                                        "strlcpy",
                                                                        "strlen",
                                                                        "strnlen",
                                                                        "strstr",
                                                                        "strcasestr",
                                                                        "strcmp",
                                                                        "strcasecmp",
                                                                        "strncmp",
                                                                        "strncasecmp")
    add_cfuncs("libc", nil,         {"wchar.h", "stdlib.h"},            "wcscat",
                                                                        "wcsncat",
                                                                        "wcscpy",
                                                                        "wcsncpy",
                                                                        "wcslcpy",
                                                                        "wcslen",
                                                                        "wcsnlen",
                                                                        "wcsstr",
                                                                        "wcscasestr",
                                                                        "wcscmp",
                                                                        "wcscasecmp",
                                                                        "wcsncmp",
                                                                        "wcsncasecmp",
                                                                        "wcstombs",
                                                                        "mbstowcs")
    add_cfuncs("libc", nil,         "time.h",                           "gmtime", "mktime", "localtime")
    add_cfuncs("libc", nil,         "sys/time.h",                       "gettimeofday")
    add_cfuncs("libc", nil,         {"signal.h", "setjmp.h"},           "signal", "setjmp", "sigsetjmp{sigjmp_buf buf; sigsetjmp(buf, 0);}", "kill")
    add_cfuncs("libc", nil,         "execinfo.h",                       "backtrace")
    add_cfuncs("libc", nil,         "locale.h",                         "setlocale")
    add_cfuncs("libc", nil,         "stdio.h",                          "fputs")
    add_cfuncs("libc", nil,         "stdlib.h",                         "srandom", "random")

    -- add the interfaces for libm
    add_cfuncs("libm", nil,         "math.h",                           "sincos", 
                                                                        "sincosf", 
                                                                        "log2", 
                                                                        "log2f",
                                                                        "sqrt",
                                                                        "sqrtf",
                                                                        "acos", 
                                                                        "acosf",
                                                                        "asin",
                                                                        "asinf",
                                                                        "pow",
                                                                        "powf",
                                                                        "fmod",
                                                                        "fmodf",
                                                                        "tan",
                                                                        "tanf",
                                                                        "atan",
                                                                        "atanf",
                                                                        "atan2",
                                                                        "atan2f",
                                                                        "cos",
                                                                        "cosf",
                                                                        "sin",
                                                                        "sinf",
                                                                        "exp",
                                                                        "expf")

    -- add the interfaces for posix
    add_cfuncs("posix", nil,        {"sys/poll.h", "sys/socket.h"},     "poll")
    add_cfuncs("posix", nil,        {"sys/select.h"},                   "select")
    add_cfuncs("posix", nil,        "pthread.h",                        "pthread_mutex_init",
                                                                        "pthread_create", 
                                                                        "pthread_setspecific", 
                                                                        "pthread_getspecific",
                                                                        "pthread_key_create",
                                                                        "pthread_key_delete")
    add_cfuncs("posix", nil,        {"sys/socket.h", "fcntl.h"},        "socket")
    add_cfuncs("posix", nil,        "dirent.h",                         "opendir")
    add_cfuncs("posix", nil,        "dlfcn.h",                          "dlopen")
    add_cfuncs("posix", nil,        {"sys/stat.h", "fcntl.h"},          "open", "stat64")
    add_cfuncs("posix", nil,        "unistd.h",                         "gethostname")
    add_cfuncs("posix", nil,        "ifaddrs.h",                        "getifaddrs")
    add_cfuncs("posix", nil,        "semaphore.h",                      "sem_init")
    add_cfuncs("posix", nil,        "unistd.h",                         "getpagesize", "sysconf")
    add_cfuncs("posix", nil,        "sched.h",                          "sched_yield")
    add_cfuncs("posix", nil,        "regex.h",                          "regcomp", "regexec")
    add_cfuncs("posix", nil,        "sys/uio.h",                        "readv", "writev", "preadv", "pwritev")
    add_cfuncs("posix", nil,        "unistd.h",                         "pread64", "pwrite64")
    add_cfuncs("posix", nil,        "unistd.h",                         "fdatasync")
    add_cfuncs("posix", nil,        "copyfile.h",                       "copyfile")
    add_cfuncs("posix", nil,        "sys/sendfile.h",                   "sendfile")
    add_cfuncs("posix", nil,        "sys/epoll.h",                      "epoll_create", "epoll_wait")
    add_cfuncs("posix", nil,        "spawn.h",                          "posix_spawnp")
    add_cfuncs("posix", nil,        "unistd.h",                         "execvp", "execvpe", "fork", "vfork")
    add_cfuncs("posix", nil,        "sys/wait.h",                       "waitpid")
    add_cfuncs("posix", nil,        "unistd.h",                         "getdtablesize")
    add_cfuncs("posix", nil,        "sys/resource.h",                   "getrlimit")
    add_cfuncs("posix", nil,        "netdb.h",                          "getaddrinfo", "getnameinfo", "gethostbyname", "gethostbyaddr")

    -- add the interfaces for systemv
    add_cfuncs("systemv", nil,      {"sys/sem.h", "sys/ipc.h"},         "semget", "semtimedop")
end

-- include project directories
includes(format("tbox/%s.lua", ifelse(has_config("micro"), "micro", "xmake"))) 
if has_config("demo") then 
    includes(format("demo/%s.lua", ifelse(has_config("micro"), "micro", "xmake"))) 
end
