-- add modes: debug and release 
add_rules("mode.debug", "mode.release")

-- add target
target("${TARGETNAME}")

    -- set kind
    set_kind("binary")

    -- add files
    add_files("src/*.m") 

    -- add frameworks
    add_frameworks("Foundation", "CoreFoundation")

    -- for macosx or ios
    if is_os("macosx", "ios") then
        add_mxflags("-fobjc-arc")
    end

${FAQ}
