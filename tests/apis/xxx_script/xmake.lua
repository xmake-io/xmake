target("test")

    before_build("iphoneos|arm64", "macosx", function (target)
        assert(target:is_plat("macosx") or (target:is_plat("iphoneos") and target:is_arch("arm64")))
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

    after_build("!macosx", function (target)
        print("after_build !macosx")
    end)

    after_build("!linux", function (target)
        print("after_build !linux")
    end)

    after_build("!iphoneos", function (target)
        print("after_build !iphoneos")
    end)

    after_build("linux|*", function (target)
        assert(target:is_plat("linux"))
    end)
