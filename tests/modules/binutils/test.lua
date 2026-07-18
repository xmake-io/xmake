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

function test_bin2elf(t)
    local tempdir = "temp/binutils_bin2elf"
    os.tryrm(tempdir)
    os.mkdir(tempdir)

    -- input binary payload
    local input = path.join(tempdir, "data.bin")
    io.writefile(input, "hello world payload", {encoding = "binary"})

    -- parse the ELF header fields we care about (class, data encoding, machine, flags)
    local function _parse_elf_header(objectfile)
        local data = io.readfile(objectfile, {encoding = "binary"})
        t:require(data ~= nil and #data >= 24)
        -- magic
        t:are_equal(string.byte(data, 1), 0x7f)
        t:are_equal(string.byte(data, 2), string.byte("E"))
        t:are_equal(string.byte(data, 3), string.byte("L"))
        t:are_equal(string.byte(data, 4), string.byte("F"))
        local class = string.byte(data, 5) -- e_ident[EI_CLASS]: 1 = 32-bit, 2 = 64-bit
        local encode = string.byte(data, 6) -- e_ident[EI_DATA]: 1 = LSB, 2 = MSB
        local bigendian = (encode == 2)
        -- read a target-endian integer of nbytes at 1-based index
        local function _readint(index, nbytes)
            local value = 0
            for i = 0, nbytes - 1 do
                local byte = string.byte(data, index + i)
                if bigendian then
                    value = value * 256 + byte
                else
                    value = value + byte * (256 ^ i)
                end
            end
            return value
        end
        local machine = _readint(19, 2) -- e_machine at offset 18
        -- e_flags: offset 36 for 32-bit, 48 for 64-bit
        local flags = (class == 2) and _readint(49, 4) or _readint(37, 4)
        return {class = class, encode = encode, machine = machine, flags = flags}
    end

    local function _gen(arch)
        local objectfile = path.join(tempdir, arch .. ".o")
        binutils.bin2obj(input, objectfile, {format = "elf", arch = arch, basename = "test"})
        return _parse_elf_header(objectfile)
    end

    -- loong64: 64-bit class, LoongArch machine (issue: was wrongly detected as 32-bit)
    local loong64 = _gen("loong64")
    t:are_equal(loong64.class, 2)
    t:are_equal(loong64.encode, 1)
    t:are_equal(loong64.machine, 0x102)
    t:are_equal(loong64.flags, 0x43) -- double-float ABI + object ABI v1

    -- riscv64: double-float ABI in e_flags (issue: was soft-float, e_flags == 0)
    local riscv64 = _gen("riscv64")
    t:are_equal(riscv64.class, 2)
    t:are_equal(riscv64.machine, 0xf3)
    t:are_equal(riscv64.flags, 0x5) -- RVC + double-float

    -- riscv (32-bit): same machine/flags, 32-bit class
    local riscv = _gen("riscv")
    t:are_equal(riscv.class, 1)
    t:are_equal(riscv.machine, 0xf3)
    t:are_equal(riscv.flags, 0x5)

    -- s390x: big-endian (issue: was wrongly little-endian)
    local s390x = _gen("s390x")
    t:are_equal(s390x.class, 2)
    t:are_equal(s390x.encode, 2) -- MSB
    t:are_equal(s390x.machine, 0x16)

    -- x86_64: unchanged, little-endian 64-bit
    local x86_64 = _gen("x86_64")
    t:are_equal(x86_64.class, 2)
    t:are_equal(x86_64.encode, 1)
    t:are_equal(x86_64.machine, 0x3e)
    t:are_equal(x86_64.flags, 0)

    -- mips is big-endian, mipsel is little-endian
    -- 32-bit variants use the o32 ABI + CPIC (e_flags == 0x1004)
    local mips = _gen("mips")
    t:are_equal(mips.encode, 2)
    t:are_equal(mips.machine, 0x08)
    t:are_equal(mips.flags, 0x1004)
    local mipsel = _gen("mipsel")
    t:are_equal(mipsel.encode, 1)
    t:are_equal(mipsel.machine, 0x08)
    t:are_equal(mipsel.flags, 0x1004)

    -- 64-bit variants use the n64 ABI (implied by ELFCLASS64) + CPIC (e_flags == 0x4)
    local mips64 = _gen("mips64")
    t:are_equal(mips64.class, 2)
    t:are_equal(mips64.encode, 2)
    t:are_equal(mips64.machine, 0x08)
    t:are_equal(mips64.flags, 0x4)
    local mips64el = _gen("mips64el")
    t:are_equal(mips64el.class, 2)
    t:are_equal(mips64el.encode, 1)
    t:are_equal(mips64el.machine, 0x08)
    t:are_equal(mips64el.flags, 0x4)

    -- xmake has no separate ppc64le arch (find_platform maps powerpc64le -> ppc64) and
    -- ppc64le is the dominant modern target, so a plain "ppc64" is treated as ppc64le:
    -- little-endian + OpenPOWER ELFv2 ABI (e_flags low bits == 2)
    local ppc64 = _gen("ppc64")
    t:are_equal(ppc64.encode, 1)
    t:are_equal(ppc64.machine, 0x15)
    t:are_equal(ppc64.flags, 0x2)

    -- explicit ppc64le behaves the same
    local ppc64le = _gen("ppc64le")
    t:are_equal(ppc64le.encode, 1)
    t:are_equal(ppc64le.machine, 0x15)
    t:are_equal(ppc64le.flags, 0x2)

    -- explicit big-endian ppc64be keeps the ELFv1 ABI
    local ppc64be = _gen("ppc64be")
    t:are_equal(ppc64be.encode, 2)
    t:are_equal(ppc64be.machine, 0x15)
    t:are_equal(ppc64be.flags, 0x1)

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
