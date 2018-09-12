target("test")

    before_build("iphoneos|arm64", "macosx", function (target)
        assert(is_plat("macosx") or (is_plat("iphoneos") and is_arch("arm64")))
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
        assert(is_plat("linux"))
    end)
