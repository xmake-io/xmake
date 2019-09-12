target("modulemap")
    set_kind("binary")
    add_files("src/*.swift", "src/*.cpp")
    add_scflags("-Xcc -fmodules", "-Xcc -fmodule-map-file=src/module.modulemap")
