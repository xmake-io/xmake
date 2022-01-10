add_rules("mode.debug", "mode.release")

add_defines("_UNICODE", "UNICODE")

target("echo")
    add_rules("wdk.env.umdf", "wdk.driver")

    -- set test sign
--    set_values("wdk.sign.mode", "test")

    -- set release sign
--    set_values("wdk.sign.mode", "release")
--    set_values("wdk.sign.certfile", path.join(os.projectdir(), "xxx.cer"))

    add_files("driver/*.c")
    add_files("driver/*.inx")
    add_includedirs("exe")

target("app")
    add_rules("wdk.env.umdf", "wdk.binary")
    add_files("exe/*.cpp")

