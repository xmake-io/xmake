-- Test project for the module resolver API.
--
-- Run from this directory with:
--   xmake add_resolver
--
-- The actual assertions live in test.lua so they can follow the existing
-- Xmake API-test pattern: the xmake.lua file wires a command/task, and the
-- test module owns the test cases.

add_moduledirs("$(projectdir)/test")
add_moduledirs("test")

task("foo")
    set_category("plugin")

    on_run(function ()
        import("test", {alias = "add_resolver_test"})
        local modules = import("core.sandbox.module")
        add_resolver_test.main()
    end)

    set_menu {
        usage = "xmake add_resolver",
        description = "Run module resolver API tests"
    }