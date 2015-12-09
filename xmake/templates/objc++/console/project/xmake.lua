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

-- for macosx or ios
if os("macosx", "ios") then

    -- add framework
    add_mxflags("-framework Foundation", "-framework CoreFoundation")
    add_ldflags("-framework Foundation", "-framework CoreFoundation")

    -- enable arc?
    add_mxflags("-fobjc-arc")
end

-- add target
add_target("[targetname]")

    -- set kind
    set_kind("binary")

    -- add files
    add_files("src/*.mm") 

