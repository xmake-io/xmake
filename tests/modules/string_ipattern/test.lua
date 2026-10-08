local function check_ascii_set(t, input, expected, brackets)
    local converted = string.ipattern(input, brackets)
    for byte = 0, 127 do
        local subject = string.char(byte)
        t:are_equal(subject:match(converted) ~= nil, subject:match(expected) ~= nil)
    end
end

function test_bracket_ranges(t)
    for _, fixture in ipairs({
        {"^[a-z]$", "^[a-zA-Z]$"},
        {"^[A-Z]$", "^[a-zA-Z]$"},
        {"^[a-c]$", "^[a-cA-C]$"},
        {"^[^a-z]$", "^[^a-zA-Z]$"},
        {"^[Z-a]$", "^[Z-aAz]$"},
        {"^[@-Z]$", "^[@A-Za-z]$"},
        {"^[a-{]$", "^[a-zA-Z{]$"},
        {"^[a-b-c]$", "^[abcABC%-]$"},
        {"^[%%a-c]$", "^[%%a-cA-C]$"}
    }) do
        check_ascii_set(t, fixture[1], fixture[2], true)
    end
end

function test_bracket_boundaries(t)
    check_ascii_set(t, "^[]a]$", "^[]aA]$", true)
    check_ascii_set(t, "^[^]a]$", "^[^]aA]$", true)
    check_ascii_set(t, "^[]a]$", "^[]a]$", false)
    check_ascii_set(t, "^[^]a]$", "^[^]a]$", false)
    check_ascii_set(t, "^[a%-c%]]$", "^[aA%-cC%]]$", true)
    t:are_equal(string.ipattern("sR[cd]/.*%.c"), "[sS][rR][cd]/.*%.[cC]")
    t:are_equal(string.ipattern("sR[cd]/.*%.c", true), "[sS][rR][cCdD]/.*%.[cC]")
end

function test_lua_pattern_controls(t)
    t:are_equal(string.ipattern("src/.*%.c"), "[sS][rR][cC]/.*%.[cC]")
    t:are_equal(("SRC/test.C"):match(string.ipattern("src/.*%.c")), "SRC/test.C")
    t:are_equal(("B"):match(string.ipattern("^[a-c]$")), nil)
    t:are_equal(("b"):match(string.ipattern("^[a-c]$", false)), "b")
    t:are_equal(("%[A]\\"):match(string.ipattern("^%%%[a%]\\$")), "%[A]\\")
    t:are_equal(string.ipattern("%a%d%w%l%u%b()%1", true), "%a%d%w%l%u%b()%1")
    t:are_equal(("(Ab)"):match(string.ipattern("^%b()$", true)), "(Ab)")
    t:are_equal(("Ab Ab"):match(string.ipattern("^([a-z]+)%s+%1$", true)), "Ab")
    t:are_equal((" WORD!"):match(string.ipattern("%f[a-z]word%f[^a-z]", true)), "WORD")
    t:are_equal(("SWORD"):match(string.ipattern("%f[a-z]word%f[^a-z]", true)), nil)
    check_ascii_set(t, "^[%a%d_]$", "^[%a%d_]$", true)
end

function test_existing_caller_patterns(t)
    t:are_equal(("/LIBPATH:Dir"):match(string.ipattern("[%-/]libpath:(.*)")), "Dir")
    t:are_equal(("-DEF:example.DEF"):match(string.ipattern("[%-/]def:(.*)")), "example.DEF")
    t:are_equal(("cmake.EXE"):find(string.ipattern("%.exe$")), 6)
    t:are_equal(("https://example.org"):find(string.ipattern("https-://")), 1)
    local flag, count = ("/LIBPATH:Dir"):gsub(string.ipattern("[%-/]libpath:(.*)"), function (dir)
        return "/libpath:" .. dir
    end)
    t:are_equal(flag, "/libpath:Dir")
    t:are_equal(count, 1)
end
