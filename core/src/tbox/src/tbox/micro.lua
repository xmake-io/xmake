-- add target
target("tbox")

    -- make as a static library
    set_kind("static")

    -- add defines
    add_defines("__tb_prefix__=\"tbox\"")

    -- set the auto-generated config.h
    set_configdir("$(buildir)/$(plat)/$(arch)/$(mode)")
    add_configfiles("tbox.config.h.in")

    -- add include directories
    add_includedirs("..", {public = true})
    add_includedirs("$(buildir)/$(plat)/$(arch)/$(mode)", {public = true})

    -- add the header files for installing
    add_headerfiles("../(tbox/**.h)|**/impl/**.h")
    add_headerfiles("../(tbox/prefix/**/prefix.S)")
    add_headerfiles("../(tbox/math/impl/*.h)")
    add_headerfiles("../(tbox/utils/impl/*.h)")
    add_headerfiles("$(buildir)/$(plat)/$(arch)/$(mode)/tbox.config.h", {prefixdir = "tbox"})

    -- add options
    add_options("info", "float", "wchar", "micro", "coroutine")

    -- add the source files
    add_files("tbox.c") 
    add_files("libc/string/memset.c") 
    add_files("libc/string/memmov.c") 
    add_files("libc/string/memcpy.c") 
    add_files("libc/string/strstr.c") 
    add_files("libc/string/strdup.c") 
    add_files("libc/string/strlen.c") 
    add_files("libc/string/strnlen.c") 
    add_files("libc/string/strcmp.c") 
    add_files("libc/string/strncmp.c") 
    add_files("libc/string/stricmp.c") 
    add_files("libc/string/strnicmp.c") 
    add_files("libc/string/strlcpy.c") 
    add_files("libc/string/strncpy.c") 
    add_files("libc/stdio/vsnprintf.c") 
    add_files("libc/stdio/snprintf.c") 
    add_files("libc/stdio/printf.c") 
    add_files("libc/stdlib/stdlib.c") 
    add_files("libc/impl/libc.c") 
    add_files("libm/impl/libm.c") 
    add_files("math/impl/math.c") 
    add_files("utils/used.c") 
    add_files("utils/bits.c") 
    add_files("utils/trace.c") 
    add_files("utils/singleton.c") 
    add_files("memory/allocator.c") 
    add_files("memory/native_allocator.c") 
    add_files("memory/static_allocator.c") 
    add_files("memory/impl/static_large_allocator.c") 
    add_files("memory/impl/memory.c") 
    add_files("network/ipv4.c") 
    add_files("network/ipv6.c") 
    add_files("network/ipaddr.c") 
    add_files("network/impl/network.c") 
    add_files("platform/page.c") 
    add_files("platform/time.c") 
    add_files("platform/file.c") 
    add_files("platform/path.c") 
    add_files("platform/sched.c") 
    add_files("platform/print.c") 
    add_files("platform/memory.c") 
    add_files("platform/thread.c") 
    add_files("platform/socket.c") 
    add_files("platform/addrinfo.c") 
    add_files("platform/poller.c") 
    add_files("platform/impl/sockdata.c") 
    add_files("platform/impl/platform.c") 
    add_files("container/iterator.c") 
    add_files("container/list_entry.c") 
    add_files("container/single_list_entry.c") 

    -- add the source files for debug mode
    if is_mode("debug") then
        add_files("utils/dump.c") 
        add_files("memory/impl/prefix.c") 
        add_files("platform/backtrace.c") 
    end

    -- add the source files for float 
    if has_config("float") then
        add_files("libm/isinf.c") 
        add_files("libm/isinff.c") 
        add_files("libm/isnan.c") 
        add_files("libm/isnanf.c") 
    end

    -- add the source for the windows 
    if is_os("windows") then
        add_files("libc/stdlib/mbstowcs.c")
        add_files("platform/dynamic.c")
        add_files("platform/windows/interface/ws2_32.c")
        add_files("platform/windows/interface/mswsock.c")
        add_files("platform/windows/interface/kernel32.c")
        if is_mode("debug") then
            add_files("platform/windows/interface/dbghelp.c")
        end
    end

    -- add the source files for coroutine
    if has_config("coroutine") then
        add_files("coroutine/stackless/*.c") 
        add_files("coroutine/impl/stackless/*.c") 
    end

    -- check interfaces
    check_interfaces()
