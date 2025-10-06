function test_rand32(t)
    local set = {}
    for i = 1, 1000 do
        local r = hash.rand32()
        t:require(set[r] == nil)
        set[r] = r
    end
end

function test_rand64(t)
    local set = {}
    for i = 1, 100000 do
        local r = hash.rand64()
        t:require(set[r] == nil)
        set[r] = r
    end
end

function test_rand128(t)
    local set = {}
    for i = 1, 100000 do
        local r = hash.rand128()
        t:require(set[r] == nil)
        set[r] = r
    end
end

