import("core.base.hashset")

function test_hashset(t)
    local h = hashset.of(1, 2, 3, 5, 5, 7, 1, 9, 4, 6, 8, 0)
    t:require(h:size() == 10)
    t:require_not(h:empty())
    for item in h:items() do
        t:require(h:has(item))
        t:require_not(h:has(item + 10))
    end
    local prev = -1
    for item in h:orderitems() do
        t:require(item > prev)
        prev = item
    end
end

