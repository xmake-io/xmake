function test_remove_if(t)
    t:are_equal(table.remove_if({1, 2, 3, 4, 5, 6}, function (i, v) return (v % 2) == 0 end), {1, 3, 5})
    t:are_equal(table.remove_if({a = 1, b = 2, c = 3}, function (i, v) return (v % 2) == 0 end), {a = 1, c = 3})
end

function test_find_if(t)
    t:are_equal(table.find_if({1, 2, 3, 4, 5, 6}, function (i, v) return (v % 2) == 0 end), {2, 4, 6})
    t:are_equal(table.find_first_if({1, 2, 3, 4, 5, 6}, function (i, v) return (v % 2) == 0 end), 2)
    t:are_equal(table.find({1, 2, 4, 4, 5, 6}, 4), {3, 4})
    t:are_equal(table.find_first({1, 2, 3, 4, 5, 6}, 4), 4)
end

function test_wrap()
    t:are_equal(talbe.wrap(1), {1})
    t:are_equal(talbe.wrap(nil), {})
    t:are_equal(talbe.wrap({}), {})
    t:are_equal(talbe.wrap({1}), {1})
    t:are_equal(talbe.wrap({{}}), {{}})
end

function test_unwrap()
    t:are_equal(talbe.unwrap(1), 1)
    t:are_equal(talbe.unwrap(nil), nil)
    t:are_equal(talbe.unwrap({}), nil)
    t:are_equal(talbe.unwrap({1}), 1)
    t:are_equal(talbe.unwrap({{}}), {})
end
