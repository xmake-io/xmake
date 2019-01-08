
-- add modes: debug and release 
add_rules("mode.debug", "mode.release")

-- add frameworks
add_frameworks("Foundation", "CoreFoundation")

-- for macosx or ios
if is_os("macosx", "ios") then

    -- enable arc?
    add_mxflags("-fobjc-arc")
end

-- add target
target("[targetname]")

    -- set kind
    set_kind("binary")

    -- add files
    add_files("src/*.m") 

