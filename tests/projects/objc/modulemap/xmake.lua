target("modulemap")
    set_kind("binary")
    add_files("src/*.m")
    add_mflags("-fmodules", "-fmodule-map-file=src/module.modulemap")


