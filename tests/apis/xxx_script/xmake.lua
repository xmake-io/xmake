target("test")

    before_build("iphoneos|arm64", function (target)
        assert(vformat("$(plat)") == "iphoneos")
        assert(vformat("$(arch)") == "arm64")
    end)

    before_build("macosx", function (target)
        assert(vformat("$(plat)") == "macosx")
    end)

    before_build(function (target)
        print("before_build")
    end)

    on_build(function (target)
        print("build")
    end)

    after_build(function (target)
        print("after_build")
    end)

    after_build("linux|*", function (target)
        assert(vformat("$(plat)") == "linux")
    end)
