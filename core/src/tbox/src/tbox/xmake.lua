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
    add_includedirs("..")
    add_includedirs("$(buildir)/$(plat)/$(arch)/$(mode)")

    -- add public header directories
    add_headerdirs("..")
    add_headerdirs("$(buildir)/$(plat)/$(arch)/$(mode)")

    -- add the header files for installing
    add_headerfiles("../(tbox/**.h)|**/impl/**.h")
    add_headerfiles("../(tbox/prefix/**/prefix.S)")
    add_headerfiles("../(tbox/math/impl/*.h)")
    add_headerfiles("../(tbox/utils/impl/*.h)")
    add_headerfiles("$(buildir)/$(plat)/$(arch)/$(mode)/tbox.config.h", {prefixdir = "tbox"})

    -- add packages
    add_packages("mbedtls", "polarssl", "openssl", "pcre2", "pcre", "zlib", "mysql", "sqlite3")

    -- add options
    add_options("info", "float", "wchar", "exception")

    -- add modules
    add_options("xml", "zip", "hash", "regex", "coroutine", "object", "charset", "database")

    -- add the common source files
    add_files("*.c") 
    add_files("hash/bkdr.c", "hash/fnv32.c", "hash/adler32.c")
    add_files("math/**.c") 
    add_files("libc/**.c|string/impl/**.c") 
    add_files("utils/*.c|option.c") 
    add_files("prefix/**.c") 
    add_files("memory/**.c") 
    add_files("string/**.c") 
    add_files("stream/**.c|**/charset.c|**/zip.c") 
    add_files("network/**.c|impl/ssl/*.c") 
    add_files("algorithm/**.c") 
    add_files("container/**.c|element/obj.c") 
    add_files("libm/impl/libm.c") 
    add_files("libm/idivi8.c") 
    add_files("libm/ilog2i.c") 
    add_files("libm/isqrti.c") 
    add_files("libm/isqrti64.c") 
    add_files("libm/idivi8.c") 
    add_files("platform/*.c|context.c|exception.c", "platform/impl/*.c")

    -- add the source files for the float type
    if has_config("float") then add_files("libm/*.c") end

    -- add the source files for the xml module
    if has_config("xml") then add_files("xml/**.c") end

    -- add the source files for the regex module
    if has_config("regex") then add_files("regex/*.c") end

    -- add the source files for the hash module
    if has_config("hash") then
        add_files("hash/*.c") 
        if not is_plat("windows") then
            add_files("hash/arch/crc32.S")
        end
    end

    -- add the source files for the coroutine module
    if has_config("coroutine") then
        add_files("platform/context.c") 
        if is_plat("windows") then
            add_files("platform/arch/$(arch)/context.asm") 
        else
            add_files("platform/arch/context.S") 
        end
        add_files("coroutine/**.c") 
    end

    -- add the source files for the exception module
    if has_config("exception") then
        add_files("platform/exception.c") 
    end

    -- add the source files for the object module
    if has_config("object") then 
        add_files("object/**.c|**/xml.c|**/xplist.c")
        add_files("utils/option.c")
        add_files("container/element/obj.c")
        if has_config("xml") then
            add_files("object/impl/reader/xml.c")
            add_files("object/impl/reader/xplist.c")
            add_files("object/impl/writer/xml.c")
            add_files("object/impl/writer/xplist.c")
        end
    end

    -- add the source files for the charset module
    if has_config("charset") then 
        add_files("charset/**.c")
        add_files("stream/impl/filter/charset.c")
    end

    -- add the source files for the zip module
    if has_config("zip") then 
        add_files("zip/**.c|gzip.c|zlib.c|zlibraw.c|lzsw.c")
        add_files("stream/impl/filter/zip.c")
        if has_config("zlib") then 
            add_files("zip/gzip.c") 
            add_files("zip/zlib.c") 
            add_files("zip/zlibraw.c") 
        end
    end

    -- add the source files for the database module
    if has_config("database") then 
        add_files("database/*.c")
        if has_package("mysql") then add_files("database/impl/mysql.c") end
        if has_package("sqlite3") then add_files("database/impl/sqlite3.c") end
    end

    -- add the source files for the ssl package
    if has_package("mbedtls") then add_files("network/impl/ssl/mbedtls.c")
    elseif has_package("polarssl") then add_files("network/impl/ssl/polarssl.c") 
    elseif has_package("openssl") then add_files("network/impl/ssl/openssl.c") end

    -- add the source for the windows 
    if is_os("windows") then
        add_files("platform/windows/iocp_object.c")
        add_files("platform/windows/socket_pool.c")
        add_files("platform/windows/interface/*.c")
    end

    -- add the source for the ios 
    if is_os("ios") then
        add_files("platform/mach/ios/directory.m")
    end

    -- add the source for the android 
    if is_os("android") then
        add_files("platform/android/*.c")
    end

    -- check interfaces
    check_interfaces()
