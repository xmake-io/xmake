import("core.base.heap")

function test_cdataheap(t)
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

