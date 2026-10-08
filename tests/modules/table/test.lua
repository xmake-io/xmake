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

function test_wrap(t)
    t:are_equal(table.wrap(1), {1})
    t:are_equal(table.wrap(nil), {})
    t:are_equal(table.wrap({}), {})
    t:are_equal(table.wrap({1}), {1})
    t:are_equal(table.wrap({{}}), {{}})
    local a = table.wrap_lock({1})
    t:are_equal(table.wrap({a}), {a})
end

function test_unwrap(t)
    t:are_equal(table.unwrap(1), 1)
    t:are_equal(table.unwrap(nil), nil)
    t:are_equal(table.unwrap({}), {})
    t:are_equal(table.unwrap({1}), 1)
    t:are_equal(table.unwrap({{}}), {})
    local a = table.wrap_lock({1})
    t:are_equal(table.unwrap(a), a)
end

function test_orderkeys(t)
    -- sort by modulo 2 then from the smallest to largest
    local f = function(a, b)
        if a % 2 == 0 and b % 2 ~= 0 then
            return true
        elseif b % 2 == 0 and a % 2 ~= 0 then
            return false
        end
        return a < b
    end

    t:are_equal(table.orderkeys({[2] = 2, [1] = 1, [4] = 4, [3] = 3}, f), {2, 4, 1, 3})
    t:are_equal(table.orderkeys({[1] = 1, [2] = 2, [3] = 3, [4] = 4}), {1, 2 , 3, 4})
end

function test_join_array_order(t)
    local array = {[1] = "a", [2] = "b", [3] = "c"}
    t:are_equal(table.join(array), {"a", "b", "c"})
    t:are_equal(table.join("begin", array, "end"), {"begin", "a", "b", "c", "end"})
    t:are_equal(table.join2({"begin"}, array, "end"), {"begin", "a", "b", "c", "end"})
    t:are_equal(array, {"a", "b", "c"})
end

function test_join_mixed_table(t)
    local mixed = {[1] = "a", [2] = "b", [3] = "c", label = "source"}
    t:are_equal(table.join(mixed), {"a", "b", "c", label = "source"})
    t:are_equal(table.join2({"begin", label = "old"}, mixed, "end"),
                {"begin", "a", "b", "c", "end", label = "source"})
end

function test_join_controls(t)
    t:are_equal(table.join({"a", "b"}, {"c"}), {"a", "b", "c"})
    t:are_equal(table.join2({"a"}, {"b", "c"}), {"a", "b", "c"})
    t:are_equal(table.join({name = "first", keep = true}, {name = "second"}), {name = "second", keep = true})
    t:are_equal(table.join("a", false, "b"), {"a", false, "b"})
    local locked = table.wrap_lock({"a", "b"})
    local joined = table.join(locked)
    t:are_equal(#joined, 1)
    t:are_equal(joined[1] == locked, true)
    local sparse = {[1] = "one", [3] = "three", [0] = "zero", [1.5] = "fraction", [-1] = "negative", name = "dict"}
    local output = table.join(sparse)
    t:are_equal(#output, 5)
    t:are_equal(output.name, "dict")
    local counts = {}
    for _, value in ipairs(output) do counts[value] = (counts[value] or 0) + 1 end
    for _, value in pairs(sparse) do
        if value ~= "dict" then t:are_equal(counts[value], 1) end
    end
end

function test_join_length_metatable(t)
    local length_calls = 0
    local array = table.inherit({__len = function()
        length_calls = length_calls + 1
        return 2
    end})
    array[1], array[2] = "a", "b"
    t:are_equal(table.join(array), {"a", "b"})
    t:are_equal(length_calls, 0)
end
