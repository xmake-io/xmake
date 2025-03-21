import("core.base.queue")

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

