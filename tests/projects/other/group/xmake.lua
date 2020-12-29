add_rules("mode.debug", "mode.release")

target("test1")
    set_kind("binary")
    add_files("src/*.cpp")
    set_group("group1")

target("test2")
    set_kind("binary")
    add_files("src/*.cpp")
    set_group("group1")

target("test3")
    set_kind("binary")
    add_files("src/*.cpp")
    set_group("group1/group2")

target("test4")
    set_kind("binary")
    add_files("src/*.cpp")
    set_group("group3/group4")

target("test5")
    set_kind("binary")
    add_files("src/*.cpp")

target("test6")
    set_kind("binary")
    add_files("src/*.cpp")
