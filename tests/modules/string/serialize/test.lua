
function roundtrip(v)
    return string.serialize(v):deserialize()
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
    --t:are_equal(roundtrip({{1, 2, 3, nil, 4}}), {{1, 2, 3, nil, 4}})
end

function test_function(t)
    t:are_equal(roundtrip(function() return {} end)(), {})
    t:are_equal(roundtrip(function() return {1, 2, 3} end)(), {1, 2, 3})
    t:are_equal(roundtrip(function() return {{1, 2, 3, nil, 4}} end)(), {{1, 2, 3, nil, 4}})
end
