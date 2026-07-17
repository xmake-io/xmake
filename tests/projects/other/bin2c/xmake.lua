add_rules("mode.debug", "mode.release")

target("test")
    set_kind("binary")
    add_rules("utils.bin2c", {linewidth = 16, extensions = {".bin", ".ico"}})
    add_files("src/*.c")
    add_files("src/data.bin")
    add_files("src/xmake.ico", {nozeroend = true})
    add_files("src/asset.bin", {transform = function (inputfile, outputfile, opt)
        import("core.base.bytes")
        assert(bytes and opt.target)
        local data = io.readfile(inputfile, {encoding = "binary"})
        io.writefile(outputfile, data:reverse(), {encoding = "binary"})
    end})


