add_rules("mode.debug", "mode.release")

target("idltest_rpc")
    set_kind("binary")
    add_files("src/*.idl", {client = true, server = true})
    add_files("src/*.c")
    add_syslinks("Rpcrt4")
