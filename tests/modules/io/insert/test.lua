function test_insert_lf_empty_lines(t)
    local cases = {
        {input = "a\n\nb", lineidx = 2, expected = "a\nx\n\nb"},
        {input = "a\n\nb", lineidx = 3, expected = "a\n\nx\nb"},
        {input = "a\nb", lineidx = 2, expected = "a\nx\nb"}
    }
    local results = {}
    for _, case in ipairs(cases) do
        local filename = os.tmpfile()
        io.writefile(filename, case.input, {encoding = "binary"})
        local data = io.insert(filename, case.lineidx, "x", {encoding = "binary"})
        table.insert(results, {data = data, disk = io.readfile(filename, {encoding = "binary"})})
    end
    for idx, case in ipairs(cases) do
        t:are_equal(results[idx].data, case.expected)
        t:are_equal(results[idx].disk, case.expected)
    end
end
