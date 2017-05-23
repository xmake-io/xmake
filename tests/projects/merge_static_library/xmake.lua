-- the debug mode
if is_mode("debug") then
    
    -- enable the debug symbols
    set_symbols("debug")

    -- disable optimization
    set_optimize("none")
end

-- the release mode
if is_mode("release") then

    -- set the symbols visibility: hidden
    set_symbols("hidden")

    -- enable fastest optimization
    set_optimize("fastest")

    -- strip all symbols
    set_strip("all")
end

-- add target
target("add")

    -- set kind
    set_kind("static")

    -- add files
    add_files("src/add.c") 

-- add target
target("sub")

    -- set kind
    set_kind("static")

    -- add files
    add_files("src/sub.c") 

-- add target
target("mul")

    -- set kind
    set_kind("static")

    -- add deps
    add_deps("add", "sub")

    -- add files
    add_files("src/mul.c") 
    add_files("build/libadd.a")
    add_files("build/libsub.a")

    -- add link directory
    add_linkdirs("$(buildir)")

