target("demo")
    set_kind("binary")
    add_deps("${TARGETNAME}")
    add_defines("__tb_prefix__=\"demo\"")
    add_files("*.cpp")
    add_packages("tbox")

