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
