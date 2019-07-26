
function roundtrip(round0)
    local round1 = string.serialize(round0, false):deserialize()
    local round2 = string.serialize(round1, true):deserialize()
    local round3 = string.serialize(round2, {binary=true}):deserialize()
    local round4 = string.serialize(round3, {indent=16}):deserialize()
    local round5 = string.serialize(round4, {indent="  \r\n\t"}):deserialize()
    return round5
end

function test_number(t)
    t:are_equal(roundtrip(12), 12)
    t:are_equal(roundtrip(0), 0)
    t:are_equal(roundtrip(-1), -1)
    t:are_equal(roundtrip(7.25), 7.25)
    t:are_equal(roundtrip(math.huge), math.huge)
    t:are_equal(roundtrip(-math.huge), -math.huge)
    t:are_equal(roundtrip(math.nan), math.nan)
end

function test_boolean(t)
    t:are_equal(roundtrip(true), true)
    t:are_equal(roundtrip(false), false)
end

function test_nil(t)
    t:are_equal(roundtrip(nil), nil)
end

function test_table(t)
    t:are_equal(roundtrip({}), {})
    t:are_equal(roundtrip({1, 2, 3}), {1, 2, 3})
    t:are_equal(roundtrip({1, "", 3}), {1, "", 3})
    t:are_equal(roundtrip({{1, 2, 3, nil, 4}}), {{1, 2, 3, nil, 4}})
    t:are_equal(roundtrip({{1, 2, 3, nil, 4, [100]=5}}), {{1, 2, 3, nil, 4, [100]=5}})
    t:are_equal(roundtrip({{a=1, b=2, c=3, nil, 4}}), {{a=1, b=2, c=3, nil, 4}})
end

function test_function(t)
    t:are_equal(roundtrip(function() return {} end)(), {})
    t:are_equal(roundtrip(function() return {1, 2, 3} end)(), {1, 2, 3})
    t:are_equal(roundtrip(function() return {{1, 2, 3, nil, 4}} end)(), {{1, 2, 3, nil, 4}})
    t:are_equal(roundtrip({function() return {{1, 2, 3, nil, 4}} end})[1](), {{1, 2, 3, nil, 4}})
    t:are_equal(roundtrip({{function() return {{1, 2, 3, nil, 4}} end}})[1][1](), {{1, 2, 3, nil, 4}})
end

function test_refloop(t)
    local l1 = {}
    l1.l = l1
    local r1 = roundtrip(l1)
    t:are_same(r1.l, r1)

    local l2 = {{1}, {2}, {3}}
    l2[1].l = { root = l2, a = l2[1], b = l2[2], c = l2[3] }
    local r2 = roundtrip(l2)
    t:are_same(r2[1].l.root, r2)
    t:are_same(r2[1].l.a, r2[1])
    t:are_same(r2[1].l.b, r2[2])
    t:are_same(r2[1].l.c, r2[3])
end
