function assert_array_eq(t1, t2)
    assert(table.is_array(t1))
    assert(table.is_array(t2))
    assert(#t1 == #t2, "#t1(%d) != #t2(%d)", #t1, #t2)
    for idx, value in ipairs(t1) do
        assert(value == t2[idx], "value[%d]: %s != %s", idx, value, t2[idx])
    end
end

function test_endswith()
    assert(not ("rc"):endswith("xcadas"))
    assert(("aaaccc"):endswith("ccc"))
end

function test_startswith()
    assert(("aaaccc"):startswith("aaa"))
end

function test_split()
    -- pattern match and ignore empty string
    assert_array_eq(("1\n\n2\n3"):split('\n'), {"1", "2", "3"})
    assert_array_eq(("abc123123xyz123abc"):split('123'), {"abc", "xyz", "abc"})
    assert_array_eq(("abc123123xyz123abc"):split('[123]+'), {"abc", "xyz", "abc"})
    
    -- plain match and ignore empty string
    assert_array_eq(("1\n\n2\n3"):split('\n', {plain = true}), {"1", "2", "3"})
    assert_array_eq(("abc123123xyz123abc"):split('123', {plain = true}), {"abc", "xyz", "abc"})

    -- pattern match and contains empty string
    assert_array_eq(("1\n\n2\n3"):split('\n', {strict = true}), {"1", "", "2", "3"})
    assert_array_eq(("abc123123xyz123abc"):split('123', {strict = true}), {"abc", "", "xyz", "abc"})
    assert_array_eq(("abc123123xyz123abc"):split('[123]+', {strict = true}), {"abc", "xyz", "abc"})

    -- plain match and contains empty string
    assert_array_eq(("1\n\n2\n3"):split('\n', {plain = true, strict = true}), {"1", "", "2", "3"})
    assert_array_eq(("abc123123xyz123abc"):split('123', {plain = true, strict = true}), {"abc", "", "xyz", "abc"})

    -- limit split count
    assert_array_eq(("1\n\n2\n3"):split('\n', {limit = 2}), {"1", "2\n3"})
    assert_array_eq(("1\n\n2\n3"):split('\n', {limit = 2, strict = true}), {"1", "\n2\n3"})
    assert_array_eq(("1.2.3.4.5"):split('%.', {limit = 3}), {"1", "2", "3.4.5"})
end

function main()
    test_split()
    test_startswith()
    test_endswith()
end
