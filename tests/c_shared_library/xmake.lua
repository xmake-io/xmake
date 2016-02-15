-- the debug mode
if modes("debug") then
    
    -- enable the debug symbols
    set_symbols("debug")

    -- disable optimization
    set_optimize("none")
end

-- the release mode
if modes("release") then

    -- set the symbols visibility: hidden
    set_symbols("hidden")

    -- enable fastest optimization
    set_optimize("fastest")

    -- strip all symbols
    set_strip("all")
end

-- add target
def_target("c_shared_library")

    -- set kind
    set_kind("shared")

    -- add files
    add_files("src/interface.cpp") 

-- add target
def_target("test")

    -- set kind
    set_kind("binary")

    -- add deps
    add_deps("c_shared_library")

    -- add files
    add_files("src/test.cpp") 

    -- add links
    add_links("c_shared_library")

    -- add link directory
    add_linkdirs("$(buildir)")

