add_rules("mode.debug", "mode.release")

target("idltest_rpc_noserver")
    set_kind("binary")
    add_files("src/*.idl", {client = true, server = false})
    add_files("src/*.c")
    add_syslinks("Rpcrt4")
