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
target("interfaces")

    -- set kind
    set_kind("static")

    -- add files
    add_files("src/interfaces.rs") 

-- add target
target("[targetname]_demo")

    -- set kind
    set_kind("binary")

    -- add deps
    add_deps("interfaces")

    -- add files
    add_files("src/main.rs") 

    -- add link directory
    add_linkdirs("$(buildir)")


