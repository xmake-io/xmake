import("core.base.cli")

function test_args(t)
    local parsed = cli.parse("abc def")
    t:are_equal(#parsed, 2)
    t:are_equal(parsed[1].type, "arg")
    t:are_equal(parsed[1].value, "abc")
    t:are_equal(parsed[2].type, "arg")
    t:are_equal(parsed[2].value, "def")
end

function test_args_escaped(t)
    local parsed = cli.parse([[a\\bc "def \"g"]])
    t:are_equal(#parsed, 2)
    t:are_equal(parsed[1].type, "arg")
    t:are_equal(parsed[1].value, "a\\bc")
    t:are_equal(parsed[2].type, "arg")
    t:are_equal(parsed[2].value, "def \"g")
end

function test_long(t)
    local parsed = cli.parse([[--long-flag --long-option="1 3" --long-option:=2 args]])
    t:are_equal(#parsed, 4)
    t:are_equal(parsed[1].type, "flag")
    t:are_equal(parsed[1].key, "long-flag")
    t:are_equal(parsed[2].type, "option")
    t:are_equal(parsed[2].key, "long-option")
    t:are_equal(parsed[2].value, "1 3")
    t:are_equal(parsed[3].type, "option")
    t:are_equal(parsed[3].key, "long-option")
    t:are_equal(parsed[3].value, "=2")
end

function test_raw(t)
    local parsed = cli.parse([[--long-flag -- --long-option="1 3" --long-option:=2 args -rx]])
    t:are_equal(#parsed, 6)
    t:are_equal(parsed[1].type, "flag")
    t:are_equal(parsed[1].key, "long-flag")
    t:are_equal(parsed[2].type, "sep")
    t:are_equal(parsed[3].type, "arg")
    t:are_equal(parsed[3].value, "--long-option=1 3")
    t:are_equal(parsed[4].type, "arg")
    t:are_equal(parsed[4].value, "--long-option:=2")
    t:are_equal(parsed[5].type, "arg")
    t:are_equal(parsed[5].value, "args")
    t:are_equal(parsed[6].type, "arg")
    t:are_equal(parsed[6].value, "-rx")
end

function test_short1(t)
    local parsed = cli.parse([[-rx args -args]], {})
    t:are_equal(#parsed, 3)
    t:are_equal(parsed[1].type, "option")
    t:are_equal(parsed[1].key, "r")
    t:are_equal(parsed[1].value, "x")
    t:are_equal(parsed[3].type, "arg")
    t:are_equal(parsed[3].value, "-args")
end

function test_short2(t)
    local parsed = cli.parse([[-r x args args]], {})
    t:are_equal(#parsed, 3)
    t:are_equal(parsed[1].type, "option")
    t:are_equal(parsed[1].key, "r")
    t:are_equal(parsed[1].value, "x")
end

function test_short3(t)
    local parsed = cli.parse([[-r"x d" args args]], {})
    t:are_equal(#parsed, 3)
    t:are_equal(parsed[1].type, "option")
    t:are_equal(parsed[1].key, "r")
    t:are_equal(parsed[1].value, "x d")
end

function test_short4(t)
    local parsed = cli.parse([["-rx d" args args]], {})
    t:are_equal(#parsed, 3)
    t:are_equal(parsed[1].type, "option")
    t:are_equal(parsed[1].key, "r")
    t:are_equal(parsed[1].value, "x d")
end

function test_short5(t)
    local parsed = cli.parse([[-r "x d" args args]], {})
    t:are_equal(#parsed, 3)
    t:are_equal(parsed[1].type, "option")
    t:are_equal(parsed[1].key, "r")
    t:are_equal(parsed[1].value, "x d")
end


function test_short_flags1(t)
    local parsed = cli.parse([[-rx args args]], {"r"})
    t:are_equal(#parsed, 3)
    t:are_equal(parsed[1].type, "flag")
    t:are_equal(parsed[1].key, "r")
    t:are_equal(parsed[2].type, "option")
    t:are_equal(parsed[2].key, "x")
    t:are_equal(parsed[2].value, "args")
end

function test_short_flags2(t)
    local parsed = cli.parse([[-r x args args]], {"r"})
    t:are_equal(#parsed, 4)
    t:are_equal(parsed[1].type, "flag")
    t:are_equal(parsed[1].key, "r")
    t:are_equal(parsed[2].type, "arg")
    t:are_equal(parsed[2].value, "x")
end

function test_short_flags3(t)
    local parsed = cli.parse([[-r"x d" args args]], {"r"})
    t:are_equal(#parsed, 4)
    t:are_equal(parsed[1].type, "flag")
    t:are_equal(parsed[1].key, "r")
    t:are_equal(parsed[2].type, "option")
    t:are_equal(parsed[2].key, "x")
    t:are_equal(parsed[2].value, " d")
end

function test_short_flags4(t)
    local parsed = cli.parse([["-rx d" args args]], {"r"})
    t:are_equal(#parsed, 4)
    t:are_equal(parsed[1].type, "flag")
    t:are_equal(parsed[1].key, "r")
    t:are_equal(parsed[2].type, "option")
    t:are_equal(parsed[2].key, "x")
    t:are_equal(parsed[2].value, " d")
end

function test_short_flags5(t)
    local parsed = cli.parse([[-r "x d" args args]], {"r"})
    t:are_equal(#parsed, 4)
    t:are_equal(parsed[1].type, "flag")
    t:are_equal(parsed[1].key, "r")
    t:are_equal(parsed[2].type, "arg")
    t:are_equal(parsed[2].value, "x d")
end
