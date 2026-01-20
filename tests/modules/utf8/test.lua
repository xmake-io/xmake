
function test_len(t)
    t:are_equal(utf8.len("A"), 1)
    t:are_equal(utf8.len("¢"), 1)
    t:are_equal(utf8.len("€"), 1)
    t:are_equal(utf8.len("𐍈"), 1)
    t:are_equal(utf8.len("ab"), 2)
    t:are_equal(utf8.len("A€B"), 3)
    t:are_equal(utf8.len("你好"), 2)
end

function test_char(t)
    t:are_equal(utf8.char(65), "A")
    t:are_equal(utf8.char(0x20AC), "€")
    t:are_equal(utf8.char(65, 66, 67), "ABC")
end

function test_codepoint(t)
    t:are_equal(utf8.codepoint("A"), 65)
    t:are_equal(utf8.codepoint("€"), 0x20AC)
    local c1, c2, c3 = utf8.codepoint("ABC", 1, 3)
    t:are_equal(c1, 65)
    t:are_equal(c2, 66)
    t:are_equal(c3, 67)

    -- test range
    t:are_equal(utf8.codepoint("ABC", 2), 66)
    t:are_equal(utf8.codepoint("ABC", 2, 2), 66)
end

function test_offset(t)
    t:are_equal(utf8.offset("ABC", 1), 1)
    t:are_equal(utf8.offset("ABC", 2), 2)
    t:are_equal(utf8.offset("ABC", 4), 4)
    t:are_equal(utf8.offset("ABC", 5), nil)

    -- "€" is 3 bytes (0xE2 0x82 0xAC)
    t:are_equal(utf8.offset("€BC", 1), 1)
    t:are_equal(utf8.offset("€BC", 2), 4)
    t:are_equal(utf8.offset("€BC", 3), 5)

    t:are_equal(utf8.offset("你好", 1), 1)
    t:are_equal(utf8.offset("你好", 2), 4)
    t:are_equal(utf8.offset("你好", 3), 7)
end

function test_codes(t)
    local s = "A€"
    local codes = {}
    for p, c in utf8.codes(s) do
        table.insert(codes, {p, c})
    end
    t:are_equal(#codes, 2)
    t:are_equal(codes[1][1], 1)
    t:are_equal(codes[1][2], 65)
    -- "€" starts at 2? No, byte offset.
    -- "A" is 1 byte. "€" starts at 2.
    t:are_equal(codes[2][1], 2)
    t:are_equal(codes[2][2], 0x20AC)
end

function test_charpattern(t)
    t:require(utf8.charpattern)
end
