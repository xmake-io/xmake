import("core.base.queue")

function test_clear(t)
    local d = queue.new()
    d:push({})
    d:push({})
    d:push({})
    d:pop()
    d:clear()
    t:are_equal(d:size(), 0)
    t:are_equal(d:empty(), true)
    t:are_equal(d:first(), nil)
    t:are_equal(d:last(), nil)
    t:are_equal(d:pop(), nil)
    -- Clearing must release the remaining stored references as well.
    t:are_equal(d[2], nil)
    t:are_equal(d[3], nil)
    d:clear()
    d:push(42)
    t:are_equal(d:size(), 1)
    t:are_equal(d:pop(), 42)
    t:are_equal(d:empty(), true)
end

function test_push(t)
    local d = queue.new()
    d:push(1)
    d:push(2)
    d:push(3)
    d:push(4)
    d:push(5)
    t:are_equal(d:first(), 1)
    t:are_equal(d:last(), 5)
    local idx = 1
    for item in d:items() do
        t:are_equal(item, idx)
        idx = idx + 1
    end
end

function test_pop(t)
    local d = queue.new()
    d:push(1)
    d:push(2)
    d:push(3)
    d:push(4)
    d:push(5)
    d:pop()
    t:are_equal(d:first(), 2)
    t:are_equal(d:last(), 5)
    local idx = 2
    for item in d:items() do
        t:are_equal(item, idx)
        idx = idx + 1
    end
end

