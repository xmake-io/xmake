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
target("merge_static_library")

    -- set kind
    set_kind("static")

    -- add files
    add_files("../static_library_c/build/static_library_c.pkg/lib/release/$(plat)/$(arch)/*.a") 

-- add target
target("test")

    -- set kind
    set_kind("binary")

    -- add deps
    add_deps("merge_static_library")

    -- add files
    add_files("src/test.c") 

    -- add links
    add_links("merge_static_library")

    -- add link directory
    add_linkdirs("$(buildir)")

