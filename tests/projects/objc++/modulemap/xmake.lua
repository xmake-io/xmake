target("modulemap")
    set_kind("binary")
    add_files("src/*.mm", "src/*.m")
    add_mxxflags("-fmodules", "-fcxx-modules", "-fmodule-map-file=src/module.modulemap")


