import("core.base.bloom_filter")

function test_bloom_filter(t)
    local filter = bloom_filter.new()
    t:are_equal(filter:set("hello"), true) -- not found
    t:are_equal(filter:set("hello"), false)
    t:are_equal(filter:set("hello"), false)
    t:are_equal(filter:get("hello"), true)

    t:are_equal(filter:set("xmake"), true) -- not found
    t:are_equal(filter:set("xmake"), false)
    t:are_equal(filter:set("xmake"), false)
    t:are_equal(filter:get("xmake"), true)

    t:are_equal(filter:get("not exists"), false)

    local data = filter:data()
    local filter2 = bloom_filter.new()
    filter2:data_set(data)
    t:are_equal(filter2:get("hello"), true)
    t:are_equal(filter2:get("xmake"), true)
    t:are_equal(filter2:get("not exists"), false)
end

