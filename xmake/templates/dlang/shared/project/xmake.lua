add_rules("mode.debug", "mode.release")

target("${TARGETNAME}")
    set_kind("shared")
    add_files("src/interfaces.d")
    add_includedirs("src", {public = true})
    add_rules("utils.symbols.export_list", {symbols = {
      "add",
      "sub"}})

target("${TARGETNAME}_demo")
    set_kind("binary")
    add_deps("${TARGETNAME}")
    add_files("src/main.d")

${FAQ}
