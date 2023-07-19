target("lz4")
    set_kind("static")
    set_warnings("all")

    -- disable c99(/TP) for windows
    if is_plat("windows") then
        set_languages("c89")
    end

    -- add header files
    add_headerfiles("lz4/lib/(*.h)")

    -- add include directories
    add_includedirs("lz4/lib", {public = true})

    -- add the common source files
    add_files("lz4/lib/*.c|lz4file.c")

    -- add definitions
    add_defines("XXH_NAMESPACE=LZ4_")

