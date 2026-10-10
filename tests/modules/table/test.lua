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

function test_clone_depth(t)
    local source = {name = "original", nested = {items = {1, 2}}}
    local shallow = table.clone(source)
    t:require_not(shallow == source)
    t:require(shallow.nested == source.nested)
    local limited = table.clone(source, 2)
    t:require_not(limited.nested == source.nested)
    t:require(limited.nested.items == source.nested.items)
    t:require(table.clone(source, 0) == source)
    t:are_equal(table.clone("value", -1), "value")
    t:are_equal(table.clone(nil, -1), nil)
end

function test_clone_deep(t)
    local source = {name = "original", nested = {items = {1, 2}}}
    local cloned = table.clone(source, -1)
    t:are_equal(cloned, source)
    t:require_not(cloned == source)
    t:require_not(cloned.nested == source.nested)
    t:require_not(cloned.nested.items == source.nested.items)
    cloned.nested.items[1] = 3
    t:are_equal(source.nested.items[1], 1)
    local empty = {}
    t:require_not(table.clone(empty, -1) == empty)
end
