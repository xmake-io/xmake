
function test_endswith(t)
    t:require(("aaaccc"):endswith("ccc"))
    t:require(("aaaccc"):endswith("aaaccc"))
    t:require_not(("rc"):endswith("xcadas"))
    t:require_not(("aaaccc "):endswith("%s"))
end

function test_startswith(t)
    t:require(("aaaccc"):startswith("aaa"))
    t:require(("aaaccc"):startswith("aaaccc"))
    t:require_not(("rc"):startswith("xcadas"))
    t:require_not(("  aaaccc"):startswith("%s"))
end

function test_trim(t)
    t:are_equal((""):trim(), "")
    t:are_equal(("   "):trim(), "")
    t:are_equal((""):trim(""), "")
    t:are_equal(("   "):trim(""), "")
    t:are_equal(("   aaa ccc   "):trim(), "aaa ccc")
    t:are_equal(("aaa ccc   "):trim(), "aaa ccc")
    t:are_equal(("   aaa ccc"):trim(), "aaa ccc")
    t:are_equal(("aaa ccc"):trim(), "aaa ccc")
    t:are_equal(("\t\naaa ccc\r\n"):trim(), "aaa ccc")
    t:are_equal(("aba"):trim("a"), "b")
end

function test_ltrim(t)
    t:are_equal((""):ltrim(), "")
    t:are_equal(("   "):ltrim(), "")
    t:are_equal((""):ltrim(""), "")
    t:are_equal(("   "):ltrim(""), "")
    t:are_equal(("   aaa ccc   "):ltrim(), "aaa ccc   ")
    t:are_equal(("aaa ccc   "):ltrim(), "aaa ccc   ")
    t:are_equal(("   aaa ccc"):ltrim(), "aaa ccc")
    t:are_equal(("aaa ccc"):ltrim(), "aaa ccc")
    t:are_equal(("\t\naaa ccc\r\n"):ltrim(), "aaa ccc\r\n")
    t:are_equal(("aba"):ltrim("a"), "ba")
end

function test_rtrim(t)
    t:are_equal((""):rtrim(), "")
    t:are_equal(("   "):rtrim(), "")
    t:are_equal((""):rtrim(""), "")
    t:are_equal(("   "):rtrim(""), "")
    t:are_equal(("   aaa ccc   "):rtrim(), "   aaa ccc")
    t:are_equal(("aaa ccc   "):rtrim(), "aaa ccc")
    t:are_equal(("   aaa ccc"):rtrim(), "   aaa ccc")
    t:are_equal(("aaa ccc"):rtrim(), "aaa ccc")
    t:are_equal(("\t\naaa ccc\r\n"):rtrim(), "\t\naaa ccc")
    t:are_equal(("aba"):rtrim("a"), "ab")
end

function test_split(t)
    -- pattern match and ignore empty string
    t:are_equal(("1\n\n2\n3"):split('\n'), {"1", "2", "3"})
    t:are_equal(("abc123123xyz123abc"):split('123'), {"abc", "xyz", "abc"})
    t:are_equal(("abc123123xyz123abc"):split('[123]+'), {"abc", "xyz", "abc"})

    -- plain match and ignore empty string
    t:are_equal(("1\n\n2\n3"):split('\n', {plain = true}), {"1", "2", "3"})
    t:are_equal(("abc123123xyz123abc"):split('123', {plain = true}), {"abc", "xyz", "abc"})

    -- pattern match and contains empty string
    t:are_equal(("1\n\n2\n3"):split('\n', {strict = true}), {"1", "", "2", "3"})
    t:are_equal(("abc123123xyz123abc"):split('123', {strict = true}), {"abc", "", "xyz", "abc"})
    t:are_equal(("abc123123xyz123abc"):split('[123]+', {strict = true}), {"abc", "xyz", "abc"})
    t:are_equal(("123abc123123xyz123abc123"):split('[123]+', {strict = true}), {"", "abc", "xyz", "abc", ""})
    t:are_equal(("123123"):split('[123]+', {strict = true}), {"", ""})
    t:are_equal((""):split('[123]+', {strict = true}), {""})

    -- plain match and contains empty string
    t:are_equal(("1\n\n2\n3"):split('\n', {plain = true, strict = true}), {"1", "", "2", "3"})
    t:are_equal(("abc123123xyz123abc"):split('123', {plain = true, strict = true}), {"abc", "", "xyz", "abc"})
    t:are_equal(("123abc123123xyz123abc123"):split('123', {plain = true, strict = true}), {"", "abc", "", "xyz", "abc", ""})
    t:are_equal(("123"):split('123', {plain = true, strict = true}), {"", ""})
    t:are_equal((""):split('123', {plain = true, strict = true}), {""})

    -- limit split count
    t:are_equal(("1\n\n2\n3"):split('\n', {limit = 2}), {"1", "2\n3"})
    t:are_equal(("1\n\n2\n3"):split('\n', {limit = 2, strict = true}), {"1", "\n2\n3"})
    t:are_equal(("\n1\n\n2\n3"):split('\n', {limit = 2, strict = true}), {"", "1\n\n2\n3"})
    t:are_equal(("1.2.3.4.5"):split('%.', {limit = 3}), {"1", "2", "3.4.5"})
    t:are_equal(("123.45"):split('%.', {limit = 3}), {"123", "45"})
    t:are_equal((""):split('123', {plain = true, limit = 2, strict = true}), {""})
    t:are_equal(("123123"):split('123', {plain = true, limit = 2, strict = true}), {"", "123"})
end

function test_lastof(t)
    t:are_equal(("1.2.3.4.5"):lastof('%.'), 8)
    t:are_equal(("1.2.3.4.5"):lastof('.', true), 8)
    t:are_equal(("/home/file.txt"):lastof('[/\\]'), 6)
    t:are_equal(("/home/file.txt"):lastof('/', true), 6)
    t:are_equal(("/home/file.txt"):lastof('/home', true), 1)
    t:are_equal(("/home/file.txt"):lastof('[/\\]home'), 1)
end

function test_replace(t)
    t:are_equal(("123xyz456xyz789xyz"):replace("123", "000"), "000xyz456xyz789xyz")
    t:are_equal(("123xyz456xyz789xyz"):replace("xyz", "000"), "123000456000789000")
    t:are_equal(("123xyz456xyz789xyz"):replace("123", "000", {plain = true}), "000xyz456xyz789xyz")
    t:are_equal(("123xyz456xyz789xyz"):replace("xyz", "000", {plain = true}), "123000456000789000")
    t:are_equal(("123$xyz456xyz789xyz"):replace("123$", "000"), "123$xyz456xyz789xyz")
    t:are_equal(("123xyz$456xyz$789xyz$"):replace("xyz$", "000"), "123xyz$456xyz$789xyz$")
    t:are_equal(("123$xyz456xyz789xyz"):replace("123$", "000", {plain = true}), "000xyz456xyz789xyz")
    t:are_equal(("123xyz$456xyz$789xyz$"):replace("xyz$", "000", {plain = true}), "123000456000789000")
end
