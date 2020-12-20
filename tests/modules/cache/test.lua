import("core.cache.memcache")

function test_memcache(t)
    memcache.set2("mycache", "foo", "bar", "1")
    t:are_equal(memcache.get2("mycache", "foo", "bar"), "1")
    memcache.clear("mycache")
    t:are_equal(memcache.get2("mycache", "foo", "bar"), nil)
    memcache.set2("mycache", "foo", "bar", "1")
    memcache.clear()
    t:are_equal(memcache.get2("mycache", "foo", "bar"), nil)
end

