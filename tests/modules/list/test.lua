import("core.base.list")

function test_push(t)
    local d = list.new()
    d:push({v = 1})
    d:push({v = 2})
    d:push({v = 3})
    d:push({v = 4})
    d:push({v = 5})
    t:are_equal(d:first().v, 1)
    t:are_equal(d:last().v, 5)
    local idx = 1
    for item in d:items() do
        t:are_equal(item.v, idx)
        idx = idx + 1
    end
end

function test_insert(t)
    local d = list.new()
    local v3 = {v = 3}
    d:insert({v = 1})
    d:insert({v = 2})
    d:insert(v3)
    d:insert({v = 5})
    d:insert({v = 4}, v3)
    t:are_equal(d:first().v, 1)
    t:are_equal(d:last().v, 5)
    local idx = 1
    for item in d:items() do
        t:are_equal(item.v, idx)
        idx = idx + 1
    end
end

function test_remove(t)
    local d = list.new()
    local v3 = {v = 3}
    d:insert({v = 1})
    d:insert({v = 2})
    d:insert(v3)
    d:insert({v = 3})
    d:insert({v = 4})
    d:insert({v = 5})
    d:remove(v3)
    t:are_equal(d:first().v, 1)
    t:are_equal(d:last().v, 5)
    local idx = 1
    for item in d:items() do
        t:are_equal(item.v, idx)
        idx = idx + 1
    end
end

function test_remove_first(t)
    local d = list.new()
    d:push({v = 1})
    d:push({v = 2})
    d:push({v = 3})
    d:push({v = 4})
    d:push({v = 5})
    d:remove_first()
    t:are_equal(d:first().v, 2)
    t:are_equal(d:last().v, 5)
    local idx = 2
    for item in d:items() do
        t:are_equal(item.v, idx)
        idx = idx + 1
    end
end

function test_remove_last(t)
    local d = list.new()
    d:push({v = 1})
    d:push({v = 2})
    d:push({v = 3})
    d:push({v = 4})
    d:push({v = 5})
    d:remove_last()
    t:are_equal(d:first().v, 1)
    t:are_equal(d:last().v, 4)
    local idx = 1
    for item in d:items() do
        t:are_equal(item.v, idx)
        idx = idx + 1
    end
end

function test_for_remove(t)
    local d = list.new()
    d:push({v = 1})
    d:push({v = 2})
    d:push({v = 3})
    d:push({v = 4})
    d:push({v = 5})
    t:are_equal(d:first().v, 1)
    t:are_equal(d:last().v, 5)
    local idx = 1
    local item = d:first()
    while item ~= nil do
        local next = d:next(item)
        t:are_equal(item.v, idx)
        d:remove(item)
        item = next
        idx = idx + 1
    end
    t:require(d:empty())
end

function test_rfor_remove(t)
    local d = list.new()
    d:push({v = 1})
    d:push({v = 2})
    d:push({v = 3})
    d:push({v = 4})
    d:push({v = 5})
    t:are_equal(d:first().v, 1)
    t:are_equal(d:last().v, 5)
    local idx = 5
    local item = d:last()
    while item ~= nil do
        local prev = d:prev(item)
        t:are_equal(item.v, idx)
        d:remove(item)
        item = prev
        idx = idx - 1
    end
    t:require(d:empty())
end

function test_insert_first(t)
    local d = list.new()
    d:push({v = 2})
    d:push({v = 3})
    d:push({v = 4})
    d:push({v = 5})
    d:insert_first({v = 1})
    t:are_equal(d:first().v, 1)
    t:are_equal(d:last().v, 5)
    local idx = 1
    for item in d:items() do
        t:are_equal(item.v, idx)
        idx = idx + 1
    end
end

function test_insert_last(t)
    local d = list.new()
    d:push({v = 1})
    d:push({v = 2})
    d:push({v = 3})
    d:push({v = 4})
    d:insert_last({v = 5})
    t:are_equal(d:first().v, 1)
    t:are_equal(d:last().v, 5)
    local idx = 1
    for item in d:items() do
        t:are_equal(item.v, idx)
        idx = idx + 1
    end
end


function test_pop_and_shift_return_removed_items(t)
    local d = list.new()
    local first = {v = 1}
    local middle = {v = 2}
    local last = {v = 3}
    d:push(first)
    d:push(middle)
    d:push(last)
    t:are_equal(d:pop(), last)
    t:are_equal(d:shift(), first)
    t:are_equal(d:size(), 1)
    t:are_equal(d:pop(), middle)
    t:require(d:empty())
    t:are_equal(d:pop(), nil)
    t:are_equal(d:shift(), nil)
    t:are_equal(d:size(), 0)
end

function test_shift_returns_singleton(t)
    local d = list.new()
    local item = {v = 1}
    d:unshift(item)
    t:are_equal(d:shift(), item)
    t:require(d:empty())
    t:are_equal(d:first(), nil)
    t:are_equal(d:last(), nil)
end
