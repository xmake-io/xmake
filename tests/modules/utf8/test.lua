
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

function test_sub(t)
    t:are_equal(utf8.sub("ABC", 1, 1), "A")
    t:are_equal(utf8.sub("ABC", 2, 2), "B")
    t:are_equal(utf8.sub("ABC", 1, 2), "AB")
    t:are_equal(utf8.sub("你好", 1, 1), "你")
    t:are_equal(utf8.sub("你好", 2, 2), "好")
    t:are_equal(utf8.sub("你好", 1, 2), "你好")
    
    -- mixed
    t:are_equal(utf8.sub("A你好B", 2, 3), "你好")
    t:are_equal(utf8.sub("A你好B", 1, 3), "A你好")
    t:are_equal(utf8.sub("A你好B", 2, 4), "你好B")

    -- negative
    t:are_equal(utf8.sub("ABC", -1), "C")
    t:are_equal(utf8.sub("ABC", -2), "BC")
    t:are_equal(utf8.sub("你好", -1), "好")
    t:are_equal(utf8.sub("你好", -2), "你好")
    t:are_equal(utf8.sub("你好", 1, -1), "你好")
    t:are_equal(utf8.sub("你好", 1, -2), "你")

    -- out of bounds
    t:are_equal(utf8.sub("ABC", 4), "")
    t:are_equal(utf8.sub("ABC", 1, 5), "ABC")
    t:are_equal(utf8.sub("ABC", 0), "ABC")
    t:are_equal(utf8.sub("ABC", -10), "ABC")
end

function test_lastof(t)
    t:are_equal(utf8.lastof("ABC", "A"), 1)
    t:are_equal(utf8.lastof("ABC", "B"), 2)
    t:are_equal(utf8.lastof("ABC", "C"), 3)
    t:are_equal(utf8.lastof("ABCA", "A"), 4)

    t:are_equal(utf8.lastof("你好", "你"), 1)
    t:are_equal(utf8.lastof("你好", "好"), 2)
    t:are_equal(utf8.lastof("你好你", "你"), 3)

    t:are_equal(utf8.lastof("A你好A", "A"), 4)
    t:are_equal(utf8.lastof("A你好A", "好"), 3)

    t:are_equal(utf8.lastof("ABC", "D"), nil)
    
    -- plain
    t:are_equal(utf8.lastof("ABC", "A", true), 1)
    t:are_equal(utf8.lastof("ABC", "B", true), 2)
    t:are_equal(utf8.lastof("ABC", ".", true), nil)

    -- pattern
    t:are_equal(utf8.lastof("ABC", "."), 3)
    t:are_equal(utf8.lastof("你好", "."), 2)
end

function test_find(t)
    -- plain
    t:are_equal({utf8.find("你好", "你", 1, true)}, {1, 1})
    t:are_equal({utf8.find("你好你", "你", 2, true)}, {3, 3})
    t:are_equal({utf8.find("A你好A", "A", 2, true)}, {4, 4})
    t:are_equal(utf8.find("ABC", "D", 1, true), nil)
    t:are_equal({utf8.find("ABC", "", 1, true)}, {1, 0})

    -- pattern matching (default)
    t:are_equal({utf8.find("ABC", "B")}, {2, 2})
    t:are_equal({utf8.find("ABC", "([BC])")}, {2, 2, "B"}) -- Capture
    t:are_equal({utf8.find("ABC", "(.)(.)")}, {1, 2, "A", "B"})

    -- UTF-8 pattern matching (byte-based)
    -- "你" is 3 bytes. "." matches first byte.
    t:are_equal({utf8.find("你好", ".")}, {1, 1})
    
    -- "你好", "好" -> bytes 4-6.
    t:are_equal({utf8.find("你好", "好")}, {2, 2})
    
    -- "你好", "..." (3 dots) -> matches 3 bytes (whole "你").
    t:are_equal({utf8.find("你好", "...")}, {1, 1})
    
    -- "A你好", "%w" -> matches "A".
    t:are_equal({utf8.find("A你好", "%w")}, {1, 1})
end

function test_width(t)
    -- char/codepoint width
    t:are_equal(utf8.width(string.byte("A")), 1)
    t:are_equal(utf8.width(utf8.codepoint("€")), 1)
    t:are_equal(utf8.width(utf8.codepoint("你")), 2)
    t:are_equal(utf8.width(0), 0)
    t:are_equal(utf8.width(0x09), 4) -- TAB

    -- string width
    t:are_equal(utf8.width("A"), 1)
    t:are_equal(utf8.width("ABC"), 3)
    t:are_equal(utf8.width("你好"), 4)
    t:are_equal(utf8.width("A你好"), 5)
    t:are_equal(utf8.width("A\tB"), 6) -- 1 + 4 + 1
end

function test_wcwidth(t)
    -- char/codepoint width
    t:are_equal(utf8.wcwidth(string.byte("A")), 1)
    t:are_equal(utf8.wcwidth(utf8.codepoint("€")), 1)
    t:are_equal(utf8.wcwidth(utf8.codepoint("你")), 2)
end

function test_wcswidth(t)
    -- string width
    t:are_equal(utf8.wcswidth("A"), 1)
    t:are_equal(utf8.wcswidth("ABC"), 3)
    t:are_equal(utf8.wcswidth("你好"), 4)
    t:are_equal(utf8.wcswidth("A你好"), 5)
    t:are_equal(utf8.wcswidth("A\tB"), 6)
end
