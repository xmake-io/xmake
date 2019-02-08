includes("check_cfuncs.lua")

-- option: demo
option("demo")
    set_default(true)
    set_showmenu(true)
    set_category("option")
    set_description("Enable or disable the demo module")
option_end()

-- option: micro
option("micro")
    set_default(false)
    set_showmenu(true)
    set_category("option")
    set_description("Compile micro core library for the embed system.")
    set_configvar("TB_CONFIG_MICRO_ENABLE", 1)
option_end()

-- option: small
option("small")
    set_default(true)
    set_showmenu(true)
    set_category("option")
    set_description("Enable the small compile mode and disable all modules.")
option_end()

-- option: wchar
option("wchar")
    add_ctypes("wchar_t")
    set_configvar("TB_CONFIG_TYPE_HAVE_WCHAR", 1)
option_end()

-- option: float
option("float")
    set_default(true)
    set_showmenu(true)
    set_category("option")
    set_description("Enable or disable the float type")
    add_deps("micro")
    set_configvar("TB_CONFIG_TYPE_HAVE_FLOAT", 1)
    after_check(function (option)
        if option:dep("micro"):enabled() then
            option:enable(false)
        end
    end)
option_end()

-- option: info
option("info")
    set_default(true)
    set_showmenu(true)
    set_category("option")
    set_description("Enable or disable to get some info, .e.g version ..")
    add_deps("small", "micro")
    set_configvar("TB_CONFIG_INFO_HAVE_VERSION", 1)
    set_configvar("TB_CONFIG_INFO_TRACE_MORE", 1)
    after_check(function (option)
        if option:dep("small"):enabled() or option:dep("micro"):enabled() then
            option:enable(false)
        end
    end)
option_end()

-- option: exception
option("exception")
    set_default(false)
    set_showmenu(true)
    set_category("option")
    set_description("Enable or disable the exception.")
    set_configvar("TB_CONFIG_EXCEPTION_ENABLE", 1)
option_end()

-- option: deprecated
option("deprecated")
    set_default(false)
    set_showmenu(true)
    set_category("option")
    set_description("Enable or disable the deprecated interfaces.")
    set_configvar("TB_CONFIG_API_HAVE_DEPRECATED", 1)
option_end()

-- add modules
for _, name in ipairs({"xml", "zip", "hash", "regex", "object", "charset", "database", "coroutine"}) do
    option(name)
        set_default(true)
        set_showmenu(true)
        set_category("module")
        set_description(format("The %s module", name))
        add_deps("small", "micro")
        set_configvar("TB_CONFIG_MODULE_HAVE_" .. name:upper(), 1)
        after_check(function (option)
            if name ~= "hash" and name ~= "charset" then 
                if option:dep("small"):enabled() or option:dep("micro"):enabled() then
                    option:enable(false)
                end
            end
        end)
    option_end()
end

-- define options for package
for _, name in ipairs({"zlib", "mysql", "sqlite3", "openssl", "polarssl", "mbedtls", "pcre2", "pcre"}) do
    option(name)
        add_deps("small", "micro")
        set_default(true)
        set_showmenu(true)
        set_description("Enable the " .. name .. " package.")
        before_check(function (option)
            if option:dep("small"):enabled() or option:dep("micro"):enabled() then
                option:enable(false)
            end
        end)
    option_end()
end

-- add requires
local groups = {nil, nil, nil, "ssl", "ssl", "ssl", "pcre", "pcre"}
for idx, require_name in ipairs({"zlib", "sqlite3", "mysql", "mbedtls 2.13.*", "openssl 1.1.*", "polarssl", "pcre2", "pcre"}) do
    local name = require_name:split('%s')[1]
    if has_config(name) then
        add_requires(require_name, {optional = true, group = groups[idx], on_load = function (package)
            package:set("configvar", {["TB_CONFIG_PACKAGE_HAVE_" .. name:upper()] = 1})
        end})
    end
end

-- get function name 
--
-- sigsetjmp
-- sigsetjmp((void*)0, 0)
-- sigsetjmp{sigsetjmp((void*)0, 0);}
-- sigsetjmp{int a = 0; sigsetjmp((void*)a, a);}
--
function get_function_name(func)
    local name, code = string.match(func, "(.+){(.+)}")
    if code == nil then
        local pos = func:find("%(")
        if pos then
            name = func:sub(1, pos - 1)
        else
            name = func
        end
    end
    return name:trim()
end

-- check c functions in the given module
function check_module_cfuncs(module, includes, ...)
    for _, func in ipairs({...}) do
        local funcname = get_function_name(func)
        configvar_check_cfuncs(("TB_CONFIG_%s_HAVE_%s"):format(module:upper(), funcname:upper()), func, {name = module .. "_" .. funcname, includes = includes})
    end
end

-- check interfaces
function check_interfaces()

    -- check the interfaces for libc
    check_module_cfuncs("libc", {"string.h", "stdlib.h"},           
        "memcpy",
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
    check_module_cfuncs("libc", {"wchar.h", "stdlib.h"},            
        "wcscat",
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
    check_module_cfuncs("libc", "time.h",                           "gmtime", "mktime", "localtime")
    check_module_cfuncs("libc", "sys/time.h",                       "gettimeofday")
    check_module_cfuncs("libc", {"signal.h", "setjmp.h"},           "signal", "setjmp", "sigsetjmp{sigjmp_buf buf; sigsetjmp(buf, 0);}", "kill")
    check_module_cfuncs("libc", "execinfo.h",                       "backtrace")
    check_module_cfuncs("libc", "locale.h",                         "setlocale")
    check_module_cfuncs("libc", "stdio.h",                          "fputs")
    check_module_cfuncs("libc", "stdlib.h",                         "srandom", "random")

    -- add the interfaces for libm
    check_module_cfuncs("libm", "math.h", 
        "sincos", 
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
    check_module_cfuncs("posix", {"sys/poll.h", "sys/socket.h"},     "poll")
    check_module_cfuncs("posix", {"sys/select.h"},                   "select")
    check_module_cfuncs("posix", "pthread.h",                        
        "pthread_mutex_init",
        "pthread_create", 
        "pthread_setspecific", 
        "pthread_getspecific",
        "pthread_key_create",
        "pthread_key_delete")
    check_module_cfuncs("posix", {"sys/socket.h", "fcntl.h"},        "socket")
    check_module_cfuncs("posix", "dirent.h",                         "opendir")
    check_module_cfuncs("posix", "dlfcn.h",                          "dlopen")
    check_module_cfuncs("posix", {"sys/stat.h", "fcntl.h"},          "open", "stat64")
    check_module_cfuncs("posix", "unistd.h",                         "gethostname")
    check_module_cfuncs("posix", "ifaddrs.h",                        "getifaddrs")
    check_module_cfuncs("posix", "semaphore.h",                      "sem_init")
    check_module_cfuncs("posix", "unistd.h",                         "getpagesize", "sysconf")
    check_module_cfuncs("posix", "sched.h",                          "sched_yield")
    check_module_cfuncs("posix", "regex.h",                          "regcomp", "regexec")
    check_module_cfuncs("posix", "sys/uio.h",                        "readv", "writev", "preadv", "pwritev")
    check_module_cfuncs("posix", "unistd.h",                         "pread64", "pwrite64")
    check_module_cfuncs("posix", "unistd.h",                         "fdatasync")
    check_module_cfuncs("posix", "copyfile.h",                       "copyfile")
    check_module_cfuncs("posix", "sys/sendfile.h",                   "sendfile")
    check_module_cfuncs("posix", "sys/epoll.h",                      "epoll_create", "epoll_wait")
    check_module_cfuncs("posix", "spawn.h",                          "posix_spawnp")
    check_module_cfuncs("posix", "unistd.h",                         "execvp", "execvpe", "fork", "vfork")
    check_module_cfuncs("posix", "sys/wait.h",                       "waitpid")
    check_module_cfuncs("posix", "unistd.h",                         "getdtablesize")
    check_module_cfuncs("posix", "sys/resource.h",                   "getrlimit")
    check_module_cfuncs("posix", "netdb.h",                          "getaddrinfo", "getnameinfo", "gethostbyname", "gethostbyaddr")

    -- add the interfaces for systemv
    check_module_cfuncs("systemv", {"sys/sem.h", "sys/ipc.h"},       "semget", "semtimedop")

    -- add the interfaces for valgrind
    check_module_cfuncs("valgrind", "valgrind/valgrind.h",           "VALGRIND_STACK_REGISTER(0, 0)")
end

-- include project directories
includes(format("tbox/%s.lua", ifelse(has_config("micro"), "micro", "xmake"))) 
if has_config("demo") then 
    includes(format("demo/%s.lua", ifelse(has_config("micro"), "micro", "xmake"))) 
end
