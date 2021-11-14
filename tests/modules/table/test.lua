function test_remove_if(t)
    t:are_equal(table.remove_if({1, 2, 3, 4, 5, 6}, function (t, i, v) return (v % 2) == 0 end), {1, 3, 5})
    t:are_equal(table.remove_if({a = 1, b = 2, c = 3}, function (t, i, v) return (v % 2) == 0 end), {a = 1, c = 3})
end
