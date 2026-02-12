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

    local wasmso = path.join(tempdir, "libfoo.so")
    io.writefile(wasmso, string.char(0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00))
    t:are_equal(binutils.format(wasmso), "wasm")

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

function test_deplibs(t)
    local tempdir = "temp/binutils_deplibs"
    os.tryrm(tempdir)
    os.mkdir(tempdir)

    local wasmso = path.join(tempdir, "libfoo.so")
    io.writefile(wasmso, string.char(0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00))
    local libs = binutils.deplibs(wasmso)
    t:are_equal(#libs, 0)

    os.tryrm(tempdir)
end

function test_readsyms(t)
    local tempdir = "temp/binutils_readsyms"
    os.tryrm(tempdir)
    os.mkdir(tempdir)

    local function _writebin(filepath, data)
        io.writefile(filepath, data, {encoding = "binary"})
    end

    local wasmso = path.join(tempdir, "libfoo.so")
    _writebin(wasmso, string.char(
        0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00,
        0x02, 0x0b, 0x01, 0x03, 0x65, 0x6e, 0x76, 0x03, 0x62, 0x61, 0x72, 0x00, 0x00,
        0x07, 0x07, 0x01, 0x03, 0x66, 0x6f, 0x6f, 0x00, 0x00))
    local results = binutils.readsyms(wasmso)
    t:are_equal(#results, 1)
    t:are_equal(results[1].objectfile, "libfoo.so")
    t:are_equal(#results[1].symbols, 2)
    t:are_equal(results[1].symbols[1].name, "bar")
    t:are_equal(results[1].symbols[1].type, "U")
    t:are_equal(results[1].symbols[2].name, "foo")
    t:are_equal(results[1].symbols[2].type, "T")

    local wasmso64 = path.join(tempdir, "libfoo64.so")
    _writebin(wasmso64, string.char(
        0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00,
        0x02, 0x0c, 0x01, 0x03, 0x65, 0x6e, 0x76, 0x03, 0x6d, 0x65, 0x6d, 0x02, 0x04, 0x01,
        0x07, 0x07, 0x01, 0x03, 0x66, 0x6f, 0x6f, 0x00, 0x00))
    local results64 = binutils.readsyms(wasmso64)
    t:are_equal(#results64, 1)
    t:are_equal(results64[1].objectfile, "libfoo64.so")
    t:are_equal(#results64[1].symbols, 2)
    t:are_equal(results64[1].symbols[1].name, "mem")
    t:are_equal(results64[1].symbols[1].type, "U")
    t:are_equal(results64[1].symbols[2].name, "foo")
    t:are_equal(results64[1].symbols[2].type, "T")

    local wasmlink = path.join(tempdir, "liblink.so")
    _writebin(wasmlink, string.char(
        0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00,
        0x01, 0x04, 0x01, 0x60, 0x00, 0x00,
        0x03, 0x02, 0x01, 0x00,
        0x0a, 0x04, 0x01, 0x02, 0x00, 0x0b,
        0x00, 0x13, 0x07, 0x6c, 0x69, 0x6e, 0x6b, 0x69, 0x6e, 0x67, 0x02, 0x08, 0x08, 0x01, 0x00, 0x00, 0x00, 0x03, 0x61, 0x64, 0x64))
    local resultslink = binutils.readsyms(wasmlink)
    t:are_equal(#resultslink, 1)
    t:are_equal(resultslink[1].objectfile, "liblink.so")
    t:are_equal(#resultslink[1].symbols, 1)
    t:are_equal(resultslink[1].symbols[1].name, "add")
    t:are_equal(resultslink[1].symbols[1].type, "T")

    local wasmar = path.join(tempdir, "libbar.a")
    local function _pad(str, n)
        if #str < n then
            return str .. string.rep(" ", n - #str)
        end
        return str:sub(1, n)
    end
    local function _ar_header(name, size)
        return _pad(name, 16) ..
               _pad("0", 12) ..
               _pad("0", 6) ..
               _pad("0", 6) ..
               _pad("644", 8) ..
               _pad(tostring(size), 10) ..
               "`\n"
    end
    local wasmobj = string.char(
        0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00,
        0x01, 0x04, 0x01, 0x60, 0x00, 0x00,
        0x03, 0x02, 0x01, 0x00,
        0x0a, 0x04, 0x01, 0x02, 0x00, 0x0b,
        0x00, 0x13, 0x07, 0x6c, 0x69, 0x6e, 0x6b, 0x69, 0x6e, 0x67, 0x02, 0x08, 0x08, 0x01, 0x00, 0x00, 0x00, 0x03, 0x61, 0x64, 0x64)
    local symtab = string.char(0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x50) .. "add\0"
    local ardata = "!<arch>\n" ..
                   _ar_header("/", #symtab) .. symtab .. ((#symtab % 2 == 1) and "\n" or "") ..
                   _ar_header("foo.cpp.o/", #wasmobj) .. wasmobj .. ((#wasmobj % 2 == 1) and "\n" or "")
    _writebin(wasmar, ardata)
    local resultsar = binutils.readsyms(wasmar)
    t:are_equal(#resultsar, 1)
    t:are_equal(resultsar[1].objectfile, "foo.cpp.o")
    t:are_equal(#resultsar[1].symbols, 1)
    t:are_equal(resultsar[1].symbols[1].name, "add")
    t:are_equal(resultsar[1].symbols[1].type, "T")

    os.tryrm(tempdir)
end
