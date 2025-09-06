function test_config(t)

    -- xmake
    os.tryrm("build")
    local dt1 = os.mclock()
    os.runv(os.programfile(), {"config", "-c"})
    dt1 = os.mclock() - dt1
    print("config targets/1k: xmake: %d ms", dt1)

    -- cmake
    os.tryrm("build")
    os.mkdir("build")
    local dt2 = os.mclock()
    os.runv("cmake", {"..", "-G", "Ninja"}, {curdir = "build"})
    dt2 = os.mclock() - dt2
    print("config targets/1k: cmake: %d ms", dt2)

    -- meson
    os.tryrm("build")
    local dt3 = os.mclock()
    os.runv("meson", {"setup", "build"})
    dt3 = os.mclock() - dt3
    print("config targets/1k: meson: %d ms", dt3)

    t:require((dt2 > dt1) or (dt2 + 1000 > dt1))
    t:require((dt3 > dt1) or (dt3 + 1000 > dt1))
end

