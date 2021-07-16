target("interfaces")
    set_kind("static")
    add_files("src/interfaces.rs")

target("${TARGETNAME}_demo")
    set_kind("binary")
    add_deps("interfaces")
    add_files("src/main.rs")
    add_linkdirs("$(buildir)")

${FAQ}
