add_rules("mode.debug", "mode.release")

target("idltest_norpc")
    set_kind("binary")
    add_files("src/*.idl", { proxy = false })
    add_files("src/*.c")
    add_syslinks("Rpcrt4")
