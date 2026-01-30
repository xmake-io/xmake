import("core.base.binutils")

function test_format(t)
    local tempdir = "temp/binutils_format"
    os.tryrm(tempdir)
    os.mkdir(tempdir)

    local unknown = path.join(tempdir, "unknown.bin")
    io.writefile(unknown, "12345678")
    local format = binutils.format(unknown)
    t:are_equal(format, "unknown")

    local scriptfile = path.join(tempdir, "a.sh")
    io.writefile(scriptfile, "#!/bin/sh\nexit 0\n")
    t:are_equal(binutils.format(scriptfile), "shebang")

    local apefile = path.join(tempdir, "a.ape")
    io.writefile(apefile, "MZqFpD00")
    t:are_equal(binutils.format(apefile), "ape")

    local apecom = path.join(tempdir, "a.com")
    io.writefile(apecom, "MZqFpD00")
    t:are_equal(binutils.format(apecom), "ape")

    local comfile = path.join(tempdir, "b.com")
    io.writefile(comfile, "12345678")
    t:are_equal(binutils.format(comfile), "unknown")

    local programfile = os.programfile()
    if programfile then
        local expected = "elf"
        if is_host("windows") then
            expected = "pe"
        elseif is_host("macosx", "iphoneos", "watchos", "appletvos") then
            expected = "macho"
        end
        local format = binutils.format(programfile)
        if format ~= "ape" then
            t:are_equal(format, expected)
        end
    end

    local ar = path.join(tempdir, "a.a")
    io.writefile(ar, "!<arch>\n")
    t:are_equal(binutils.format(ar), "ar")

    local elf = path.join(tempdir, "a.elf")
    io.writefile(elf, string.char(0x7f, string.byte("E"), string.byte("L"), string.byte("F"), 0, 0, 0, 0))
    t:are_equal(binutils.format(elf), "elf")

    local macho = path.join(tempdir, "a.macho")
    io.writefile(macho, string.char(0xfe, 0xed, 0xfa, 0xcf, 0, 0, 0, 0))
    t:are_equal(binutils.format(macho), "macho")

    local coff = path.join(tempdir, "a.obj")
    io.writefile(coff, string.char(0x4c, 0x01, 0, 0, 0, 0, 0, 0))
    t:are_equal(binutils.format(coff), "coff")

    local pefile = path.join(tempdir, "a.exe")
    local pe = {}
    for _ = 1, 0x44 do
        table.insert(pe, 0)
    end
    pe[1] = string.byte("M")
    pe[2] = string.byte("Z")
    pe[0x3c + 1] = 0x40
    pe[0x3c + 2] = 0
    pe[0x3c + 3] = 0
    pe[0x3c + 4] = 0
    pe[0x40 + 1] = string.byte("P")
    pe[0x40 + 2] = string.byte("E")
    pe[0x40 + 3] = 0
    pe[0x40 + 4] = 0
    io.writefile(pefile, string.char(table.unpack(pe)))
    t:are_equal(binutils.format(pefile), "pe")

    os.tryrm(tempdir)
end
