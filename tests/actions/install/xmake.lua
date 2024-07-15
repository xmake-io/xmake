add_rules("mode.debug", "mode.release")

set_version("1.0.1", {soname = true})

add_requires("libplist", {system = false, configs = {shared = true}})

target("foo")
    set_kind("shared")
    add_files("src/foo.cpp")
    add_packages("libplist", {public = true})

target("test5")
    set_kind("binary")
    add_deps("foo")
    add_files("src/main.cpp")

includes("@builtin/xpack")

xpack("test")
  add_targets("test5")
  set_formats("zip")

