includes("a", "b")
target("test")
    add_deps("a", "b")
    set_kind("phony")
