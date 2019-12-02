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
target("static_library_c")

    -- set kind
    set_kind("static")

    -- add files
    add_files("s r c/interface.c")

-- add target
target("test")

    -- set kind
    set_kind("binary")

    -- add deps
    add_deps("static_library_c")

    -- add files
    add_files("s r c/test.c")


