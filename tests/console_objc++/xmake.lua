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

-- add frameworks
add_frameworks("Foundation", "CoreFoundation")

-- for macosx or ios
if is_os("macosx", "ios") then

    -- enable arc?
    add_mxflags("-fobjc-arc")
end

-- add target
target("console_objc++")

    -- set kind
    set_kind("binary")

    -- add files
    add_files("src/*.mm") 

