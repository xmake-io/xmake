target("foo")
    set_kind("shared")
    add_files("src/foo.rs")

target("${TARGETNAME}_demo")
    set_kind("binary")
    add_deps("foo")
    add_files("src/main.rs")

    --- Make sure libstd shared library is available
    before_run(function (target)
        local outdata, errdata = os.iorun("rustc --print=sysroot")
        assert(not errdata or errdata == "", "failed to find rust sysroot:\n" .. errdata)
        local libstd = path.join(outdata:trim(), "bin")
        os.addenvs({PATH = libstd, LD_LIBRARY_PATH = libstd, DYLD_LIBRARY_PATH = libstd})
    end)

${FAQ}
