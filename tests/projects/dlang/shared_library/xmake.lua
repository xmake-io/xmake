add_rules("mode.debug", "mode.release")

target("interfaces")
    set_kind("shared")
    add_files("src/interfaces.d")
    add_includedirs("src", {public = true})
    add_rules("utils.symbols.export_list", {symbols = {
      "add",
      "sub"}})

target("test")
    set_kind("binary")
    add_deps("interfaces")
    add_files("src/main.d")

