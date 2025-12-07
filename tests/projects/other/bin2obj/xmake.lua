add_rules("mode.debug", "mode.release")

target("test")
    set_kind("binary")
    add_rules("utils.bin2obj", {extensions = {".bin", ".ico"}})
    add_files("src/*.c")
    add_files("src/data.bin", {zeroend = true})
    add_files("src/xmake.ico", {zeroend = false})
