rule("cppfront")
    set_extensions(".cpp2")
    on_build_files(function (target, batchjobs, sourcebatch, opt)
        print("on_build_files")
    end, {batch = true, distcc = true})

rule("xx")
    set_base("c++")
    add_deps("cppfront", {order = true})

target("test")
    set_kind("binary")
    add_rules("xx")
    add_files("src/*.cc")

