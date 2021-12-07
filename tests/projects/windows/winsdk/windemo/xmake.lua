-- add rules: debug/release
add_rules("mode.debug", "mode.release")

-- define target
target("test")

    -- set kind
    add_rules("win.sdk.application")

    -- add files
    add_files("*.rc", "*.cpp")

