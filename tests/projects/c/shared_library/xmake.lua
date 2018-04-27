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
target("shared_library_c")

    -- set kind
    set_kind("shared")

    -- add files
    add_files("src/interface.c") 

-- add target
target("test")

    -- set kind
    set_kind("binary")

    -- add deps
    add_deps("shared_library_c")

    -- add files
    add_files("src/test.c") 


