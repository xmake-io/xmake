import("core.package.package")

function test_load_from_repository(t)
    local packagedir = path.absolute("foo")
    local foo1 = package.load_from_repository("foo", packagedir, {})
    local foo2 = package.load_from_repository("foo", packagedir, {})
    assert(foo1 and foo2, "load_from_repository(foo) failed!")

    t:require(table.contains(table.wrap(foo1:get("defines")), "FOO_BASE"))
    t:require(table.contains(table.wrap(foo2:get("defines")), "FOO_BASE"))

    -- mutating one instance should not leak into the other
    foo1:add("defines", "FOO_LEAK")
    t:require(table.contains(table.wrap(foo1:get("defines")), "FOO_LEAK"))
    t:require_not(table.contains(table.wrap(foo2:get("defines")), "FOO_LEAK"))

    foo1:set("foo_leak", false)
    t:require(foo1:get("foo_leak") == false)
    t:require_not(foo2:get("foo_leak") == false)
end
