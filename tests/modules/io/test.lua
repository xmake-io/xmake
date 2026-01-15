function test_read(t)
    t:are_equal(io.readfile("files/utf8bom-lf-eleof"), "123\\\n456\n789\n")
    t:are_equal(io.readfile("files/utf8-crlf-neleof"), "123\\\n456\n789")
    t:are_equal(io.readfile("files/utf8-crlf-neleof", {encoding = "binary"}), "123\\\r\n456\r\n789")
    t:are_equal(io.readfile("files/utf8-crlf-neleof", {continuation = "\\"}), "123456\n789")
    t:are_equal(io.readfile("files/utf16be-lf-eleof"), "123\\\n456\n789\n")
    t:are_equal(io.readfile("files/utf16le-crlf-neleof"), "123\\\n456\n789")

    local data1 = io.readfile("files/utf8-longline-neleof")
    t:are_equal(#data1, 10000)
    t:require(data1:endswith("1234567890"))

    local data2 = io.readfile("files/utf8-longline-eleof")
    t:are_equal(#data2, 10001)
    t:require(data2:endswith("1234567890\n"))
end

function test_lines(t)
    t:are_equal(table.to_array(io.lines("files/utf8bom-lf-eleof")), {"123\\", "456", "789"})
    t:are_equal(table.to_array(io.lines("files/utf8-crlf-neleof")), {"123\\", "456", "789"})
    t:are_equal(table.to_array(io.lines("files/utf8-crlf-neleof", {encoding = "binary"})), {"123\\\r\n", "456\r\n", "789"})
    t:are_equal(table.to_array(io.lines("files/utf8-crlf-neleof", {continuation = "\\"})), {"123456", "789"})
    t:are_equal(table.to_array(io.lines("files/utf16be-lf-eleof")), {"123\\", "456", "789"})
    t:are_equal(table.to_array(io.lines("files/utf16le-crlf-neleof")), {"123\\", "456", "789"})
end

function test_readlines(t)

    function get_all_keep_crlf(file, opt)
        local fp = io.open(file, "r", opt)
        local r = {}
        while true do
            local l = fp:read("L", opt)
            if l == nil then break end
            table.insert(r, l)
        end
        t:require(fp:close())
        return r
    end

    function get_all_without_crlf(file, opt)
        local r = {}
        local fp = io.open(file, "r", opt)
        for l in fp:lines(opt) do
            table.insert(r, l)
        end
        t:require(fp:close())
        return r
    end

    t:are_equal(get_all_keep_crlf("files/utf8bom-lf-eleof"), {"123\\\n", "456\n", "789\n"})
    t:are_equal(get_all_keep_crlf("files/utf8-crlf-neleof"), {"123\\\n", "456\n", "789"})
    t:are_equal(get_all_keep_crlf("files/utf8-crlf-neleof", {encoding = "binary"}), {"123\\\r\n", "456\r\n", "789"})
    t:are_equal(get_all_keep_crlf("files/utf8-crlf-neleof", {continuation = "\\"}), {"123456\n", "789"})
    t:are_equal(get_all_keep_crlf("files/utf16be-lf-eleof"), {"123\\\n", "456\n", "789\n"})
    t:are_equal(get_all_keep_crlf("files/utf16le-crlf-neleof"), {"123\\\n", "456\n", "789"})

    t:are_equal(get_all_without_crlf("files/utf8bom-lf-eleof"), {"123\\", "456", "789"})
    t:are_equal(get_all_without_crlf("files/utf8-crlf-neleof"), {"123\\", "456", "789"})
    t:are_equal(get_all_without_crlf("files/utf8-crlf-neleof", {encoding = "binary"}), {"123\\\r\n", "456\r\n", "789"})
    t:are_equal(get_all_without_crlf("files/utf8-crlf-neleof", {continuation = "\\"}), {"123456", "789"})
    t:are_equal(get_all_without_crlf("files/utf16be-lf-eleof"), {"123\\", "456", "789"})
    t:are_equal(get_all_without_crlf("files/utf16le-crlf-neleof"), {"123\\", "456", "789"})
end

function test_prop(t)
    t:are_equal(io.open("files/utf8bom-lf-eleof"):size(), 16)
    t:are_equal(io.open("files/utf8-crlf-neleof"):size(), 14)
    t:are_equal(io.open("files/utf16be-lf-eleof"):size(), 28)
    t:are_equal(io.open("files/utf16le-crlf-neleof"):size(), 30)

    t:are_equal(io.open("files/utf8bom-lf-eleof"):path(), path.absolute("files/utf8bom-lf-eleof"))
    t:are_equal(io.open("files/utf8-crlf-neleof"):path(), path.absolute("files/utf8-crlf-neleof"))
    t:are_equal(io.open("files/utf16be-lf-eleof"):path(), path.absolute("files/utf16be-lf-eleof"))
    t:are_equal(io.open("files/utf16le-crlf-neleof"):path(), path.absolute("files/utf16le-crlf-neleof"))
end

function test_write(t)

    function write(fname, opt)
        local f = io.open(fname, "w", opt)
        f:write(123, "abc", 456, "def", "\n")
        f:close()

        -- give encoding info
        t:are_equal(io.readfile(fname, opt), "123abc456def\n")
        -- auto detect encoding
        t:are_equal(io.readfile(fname), "123abc456def\n")
    end
    write("temp/path/not/exist/utf8", {encoding = "utf8"})
    write("temp/path/not/exist/utf16", {encoding = "utf16"})
    write("temp/path/not/exist/utf16le", {encoding = "utf16le"})
    write("temp/path/not/exist/utf16be", {encoding = "utf16be"})

    os.tryrm("temp")
end

function test_convert(t)
    local src = "files/utf8bom-lf-eleof"
    local dst = "temp/convert_test.txt"
    os.mkdir("temp")
    
    -- utf8 to gbk (strip bom)
    io.convert(src, dst, {from = "utf8", to = "gbk"})
    local content = io.readfile(dst, {encoding = "binary"})
    t:are_equal(content, "123\\\n456\n789\n")
    
    -- gbk to utf8
    local src_gbk = dst
    local dst_utf8 = "temp/convert_test_utf8.txt"
    io.convert(src_gbk, dst_utf8, {from = "gbk", to = "utf8"})
    content = io.readfile(dst_utf8, {encoding = "binary"})
    t:are_equal(content, "123\\\n456\n789\n")

    -- utf8 to utf8bom
    local dst_utf8bom = "temp/convert_test_utf8bom.txt"
    io.convert(src, dst_utf8bom, {from = "utf8", to = "utf8bom"})
    content = io.readfile(dst_utf8bom, {encoding = "binary"})
    t:are_equal(content:sub(1, 3), "\239\187\191")
    t:are_equal(content:sub(4), "123\\\n456\n789\n")

    -- utf16le to utf8
    local src_utf16le = "files/utf16le-crlf-neleof"
    local dst_utf16le_to_utf8 = "temp/convert_test_utf16le_to_utf8.txt"
    io.convert(src_utf16le, dst_utf16le_to_utf8, {from = "utf16le", to = "utf8"})
    content = io.readfile(dst_utf16le_to_utf8, {encoding = "binary"})
    t:are_equal(content, "123\\\r\n456\r\n789")

    -- utf16be to utf8
    local src_utf16be = "files/utf16be-lf-eleof"
    local dst_utf16be_to_utf8 = "temp/convert_test_utf16be_to_utf8.txt"
    io.convert(src_utf16be, dst_utf16be_to_utf8, {from = "utf16be", to = "utf8"})
    content = io.readfile(dst_utf16be_to_utf8, {encoding = "binary"})
    t:are_equal(content, "123\\\n456\n789\n")

    -- utf8 to utf16le
    local dst_utf8_to_utf16le = "temp/convert_test_utf8_to_utf16le.txt"
    io.convert(src, dst_utf8_to_utf16le, {from = "utf8", to = "utf16le"})
    content = io.readfile(dst_utf8_to_utf16le, {encoding = "binary"})
    t:are_equal(content:sub(1, 2), "1\0") 

    -- utf8 to utf16be
    local dst_utf8_to_utf16be = "temp/convert_test_utf8_to_utf16be.txt"
    io.convert(src, dst_utf8_to_utf16be, {from = "utf8", to = "utf16be"})
    content = io.readfile(dst_utf8_to_utf16be, {encoding = "binary"})
    t:are_equal(content:sub(1, 2), "\0001")

    -- utf8 to utf16lebom
    local dst_utf8_to_utf16lebom = "temp/convert_test_utf8_to_utf16lebom.txt"
    io.convert(src, dst_utf8_to_utf16lebom, {from = "utf8", to = "utf16lebom"})
    content = io.readfile(dst_utf8_to_utf16lebom, {encoding = "binary"})
    t:are_equal(content:sub(1, 2), "\255\254")

    -- utf8 to utf16bom
    local dst_utf8_to_utf16bom = "temp/convert_test_utf8_to_utf16bom.txt"
    io.convert(src, dst_utf8_to_utf16bom, {from = "utf8", to = "utf16bom"})
    content = io.readfile(dst_utf8_to_utf16bom, {encoding = "binary"})
    local bom = content:sub(1, 2)
    t:require(bom == "\255\254" or bom == "\254\255")

    os.tryrm("temp")
end
