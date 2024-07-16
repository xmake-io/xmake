add_rules("mode.debug", "mode.release")

--set_version("1.0.1", {soname = true})

add_requires("libplist", {system = false, configs = {shared = true}})

target("foo")
    set_kind("shared")
    add_files("src/foo.cpp")
    add_packages("libplist", {public = true})
    add_headerfiles("src/foo.h", {public = true})
    add_installfiles("src/foo.txt", {prefixdir = "assets", public = true})
--    set_prefixdir("/", {bindir = "foo_bin", libdir = "foo_lib"})

target("app")
    set_kind("binary")
    add_deps("foo")
    add_files("src/main.cpp")
    add_rpathdirs("@loader_path/../lib", {installonly = true})
--    set_prefixdir("app")

includes("@builtin/xpack")

xpack("test")
  add_targets("app")
  set_formats("zip")

