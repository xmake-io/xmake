add_rules("mode.debug", "mode.release")
add_requires("capnproto")

target("test")
    set_kind("binary")
    set_languages("c++14")
    add_packages("capnproto")
    add_files("src/**.cc")
    add_files("proto/*.capnp", {rules = "capnproto.cpp", capnp_rootdir = "proto"})
