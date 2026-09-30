import("core.base.heap")

function test_cdataheap(t)
    if not xmake.luajit() then
        return
    end
    local h = heap.cdataheap{
        size = 100,
        ctype = [[
            struct {
                int priority;
                int order;
            }
        ]],
        cmp = function(a, b)
            if a.priority == b.priority then
                return a.order > b.order
            end
            return a.priority < b.priority
        end}
    h:push{priority = 20, order = 1}
    h:push{priority = 10, order = 2}
    h:push{priority = 10, order = 3}
    h:push{priority = 20, order = 4}
    t:are_equal(h:pop().order, 3)
    t:are_equal(h:pop().order, 2)
    t:are_equal(h:pop().order, 4)
    t:are_equal(h:pop().order, 1)
end

function test_valueheap(t)
    local h = heap.valueheap{cmp = function(a, b)
          return a.priority < b.priority
       end}
    h:push{priority = 20, etc = 'bar'}
    h:push{priority = 10, etc = 'foo'}
    t:are_equal(h:pop().priority, 10)
    t:are_equal(h:pop().priority, 20)
end


function test_pop_nonroot_rebalances_upward(t)
    local h = heap.valueheap()
    for _, value in ipairs({37, 60, 40, 53, 67, 27, 34}) do
        h:push(value)
    end
    t:are_equal(h:pop(4), 60)
    for _, expected in ipairs({27, 34, 37, 40, 53, 67}) do
        t:are_equal(h:pop(), expected)
    end
    t:are_equal(h:length(), 0)
end

function test_pop_nonroot_with_custom_comparator(t)
    local h = heap.valueheap{cmp = function(a, b) return a > b end}
    for _, value in ipairs({-37, -60, -40, -53, -67, -27, -34}) do
        h:push(value)
    end
    t:are_equal(h:pop(4), -60)
    for _, expected in ipairs({-27, -34, -37, -40, -53, -67}) do
        t:are_equal(h:pop(), expected)
    end
end

function test_pop_last_and_singleton(t)
    local h = heap.valueheap()
    h:push(1)
    h:push(2)
    t:are_equal(h:pop(2), 2)
    t:are_equal(h:pop(), 1)
    t:are_equal(h:length(), 0)
end
