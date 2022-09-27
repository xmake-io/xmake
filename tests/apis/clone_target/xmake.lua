target("test")
    set_kind("binary")
    add_files("src/*.cpp")
    after_load(function (target)
        --target:clone()
    end)

