import("core.base.dlist")

function test_push(t)
    local d = dlist.new()
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
    local d = dlist.new()
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
    local d = dlist.new()
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
    local d = dlist.new()
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
    local d = dlist.new()
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

function test_insert_head(t)
    local d = dlist.new()
    d:push({v = 2})
    d:push({v = 3})
    d:push({v = 4})
    d:push({v = 5})
    d:insert_head({v = 1})
    t:are_equal(d:first().v, 1)
    t:are_equal(d:last().v, 5)
    local idx = 1
    for item in d:items() do
        t:are_equal(item.v, idx)
        idx = idx + 1
    end
end

function test_insert_tail(t)
    local d = dlist.new()
    d:push({v = 1})
    d:push({v = 2})
    d:push({v = 3})
    d:push({v = 4})
    d:insert_tail({v = 5})
    t:are_equal(d:first().v, 1)
    t:are_equal(d:last().v, 5)
    local idx = 1
    for item in d:items() do
        t:are_equal(item.v, idx)
        idx = idx + 1
    end
end

