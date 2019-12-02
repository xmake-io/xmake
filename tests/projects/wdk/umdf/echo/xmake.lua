
-- add modes: debug and release
add_rules("mode.debug", "mode.release")

-- enable unicode
add_defines("_UNICODE", "UNICODE")

-- add target
target("echo")

    -- add rules
    add_rules("wdk.env.umdf", "wdk.driver")

    -- set test sign
--    set_values("wdk.sign.mode", "test")

    -- set release sign
--    set_values("wdk.sign.mode", "release")
--    set_values("wdk.sign.certfile", path.join(os.projectdir(), "xxx.cer"))

    -- add files
    add_files("driver/*.c")
    add_files("driver/*.inx")

    -- add includedirs
    add_includedirs("exe")

-- add target
target("app")

    -- add rules
    add_rules("wdk.env.umdf", "wdk.binary")

    -- add files
    add_files("exe/*.cpp")

