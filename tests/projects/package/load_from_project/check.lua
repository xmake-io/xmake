import("core.package.package")

function main()
    local foo1 = package.load_from_project("foo")
    local foo2 = package.load_from_project("foo")
    assert(foo1 and foo2, "load_from_project(foo) failed!")

    assert(table.contains(table.wrap(foo1:get("defines")), "FOO_BASE"), "foo1 missing FOO_BASE")
    assert(table.contains(table.wrap(foo2:get("defines")), "FOO_BASE"), "foo2 missing FOO_BASE")

    -- mutating one instance should not leak into the other
    foo1:add("defines", "FOO_LEAK")
    assert(table.contains(table.wrap(foo1:get("defines")), "FOO_LEAK"), "foo1 missing FOO_LEAK")
    assert(not table.contains(table.wrap(foo2:get("defines")), "FOO_LEAK"), "FOO_LEAK leaked into foo2")

    foo1:set("foo_leak", false)
    assert(foo1:get("foo_leak") == false, "foo1 foo_leak not set")
    assert(foo2:get("foo_leak") ~= false, "foo_leak leaked into foo2")
end
