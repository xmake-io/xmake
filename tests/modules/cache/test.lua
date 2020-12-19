import("core.cache.memcache")

function test_memcache(t)
    memcache.value_set("mycache", "myscope", "mykey", "1")
    t:are_equal(memcache.value("mycache", "myscope", "mykey"), "1")
    memcache.value_add("mycache", "myscope", "mykey", "2")
    t:are_equal(memcache.value("mycache", "myscope", "mykey"), {"1", "2"})
    memcache.clear("mycache")
    t:are_equal(memcache.value("mycache", "myscope", "mykey"), nil)
    memcache.value_set("mycache", "myscope", "mykey", "1")
    memcache.clear()
    t:are_equal(memcache.value("mycache", "myscope", "mykey"), nil)
    memcache.value_add("mycache", "myscope", "mykey", "2")
    t:are_equal(memcache.value("mycache", "myscope", "mykey"), "2")
    t:are_equal(memcache.scope("mycache", "myscope"), {mykey = "2"})
    memcache.scope_set("mycache", "myscope", {mykey = "3"})
    t:are_equal(memcache.value("mycache", "myscope", "mykey"), "3")
end

