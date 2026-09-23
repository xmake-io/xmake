function _import_sandbox_module()
    -- Pull in the sandbox module helpers used by these tests.
    import("core.sandbox.module", {
        alias = "sandbox_module",
        rootdir = path.join(os.programdir(), "core", "sandbox", "modules", "import")
    })
    return sandbox_module
end

function _clear_resolvers()
    -- Reset resolver state between tests.
    local sandbox_module = _import_sandbox_module()
    sandbox_module.clear_resolvers()
end

function _assert_equal(actual, expected)
    -- Slightly nicer assert output when values do not match.
    assert(actual == expected, string.format("expected %s, got %s", tostring(expected), tostring(actual)))
end

function _test_module_result()
    -- Resolver returns a module table directly.
    local sandbox_module = _import_sandbox_module()

    sandbox_module.clear_resolvers()

    sandbox_module.add_resolver(function (name, ctx)
        if name == "virtual.hello" then
            return ctx.module({
                hello = function ()
                    return "hello from resolver"
                end
            })
        end
        return ctx.miss()
    end)

    local mod = import("virtual.hello", {anonymous = true})
    _assert_equal(mod.hello(), "hello from resolver")

    sandbox_module.clear_resolvers()
end

function _test_file_result()
    -- Resolver returns a generated Lua file.
    local sandbox_module = _import_sandbox_module()

    sandbox_module.clear_resolvers()

    local moduledir = path.join(os.tmpdir(), "xmake-test-add-resolver-file")
    local modulefile = path.join(moduledir, "generated", "hello.lua")

    os.tryrm(moduledir)
    os.mkdir(path.directory(modulefile))

    io.writefile(modulefile, [[
function hello()
    return "hello from generated file"
end
]])

    sandbox_module.add_resolver(function (name, ctx)
        if name == "generated.hello" then
            return ctx.file(modulefile)
        end
        return ctx.miss()
    end)

    local mod = import("generated.hello", {anonymous = true})
    _assert_equal(mod.hello(), "hello from generated file")

    sandbox_module.clear_resolvers()
    os.tryrm(moduledir)
end

function _test_string_result_is_file_result()
    -- Raw string paths should behave the same as ctx.file().
    local sandbox_module = _import_sandbox_module()

    sandbox_module.clear_resolvers()

    local moduledir = path.join(os.tmpdir(), "xmake-test-add-resolver-string")
    local modulefile = path.join(moduledir, "generated", "string_hello.lua")

    os.tryrm(moduledir)
    os.mkdir(path.directory(modulefile))

    io.writefile(modulefile, [[
function hello()
    return "hello from string file"
end
]])

    sandbox_module.add_resolver(function (name, ctx)
        if name == "generated.string_hello" then
            return modulefile
        end
        return ctx.miss()
    end)

    local mod = import("generated.string_hello", {anonymous = true})
    _assert_equal(mod.hello(), "hello from string file")

    sandbox_module.clear_resolvers()
    os.tryrm(moduledir)
end

function _test_raw_table_result_is_module_result()
    -- Plain tables should be treated as module results.
    local sandbox_module = _import_sandbox_module()

    sandbox_module.clear_resolvers()

    sandbox_module.add_resolver(function (name, ctx)
        if name == "virtual.raw_table" then
            return {
                value = function ()
                    return 42
                end
            }
        end
        return ctx.miss()
    end)

    local mod = import("virtual.raw_table", {anonymous = true})
    _assert_equal(mod.value(), 42)

    sandbox_module.clear_resolvers()
end

function _test_miss_falls_through_to_later_resolver()
    -- ctx.miss() should fall through to the next resolver.
    local sandbox_module = _import_sandbox_module()

    sandbox_module.clear_resolvers()

    sandbox_module.add_resolver(function (name, ctx)
        return ctx.miss()
    end)

    sandbox_module.add_resolver(function (name, ctx)
        if name == "virtual.fallback" then
            return ctx.module({
                value = function ()
                    return "fallback"
                end
            })
        end
        return ctx.miss()
    end)

    local mod = import("virtual.fallback", {anonymous = true})
    _assert_equal(mod.value(), "fallback")

    sandbox_module.clear_resolvers()
end

function _test_nil_falls_through_to_later_resolver()
    -- nil should behave the same as ctx.miss().
    local sandbox_module = _import_sandbox_module()

    sandbox_module.clear_resolvers()

    sandbox_module.add_resolver(function (name, ctx)
        return nil
    end)

    sandbox_module.add_resolver(function (name, ctx)
        if name == "virtual.nil_fallback" then
            return ctx.module({
                value = function ()
                    return "nil fallback"
                end
            })
        end
        return ctx.miss()
    end)

    local mod = import("virtual.nil_fallback", {anonymous = true})
    _assert_equal(mod.value(), "nil fallback")

    sandbox_module.clear_resolvers()
end

function _test_cache_reuses_module_result()
    -- Resolver-backed modules should still use the normal cache.
    local sandbox_module = _import_sandbox_module()

    sandbox_module.clear_resolvers()

    local calls = 0

    sandbox_module.add_resolver(function (name, ctx)
        if name == "virtual.cached" then
            calls = calls + 1
            return ctx.module({
                calls = function ()
                    return calls
                end
            })
        end
        return ctx.miss()
    end)

    local first = import("virtual.cached", {anonymous = true})
    local second = import("virtual.cached", {anonymous = true})

    assert(first == second)
    _assert_equal(first.calls(), 1)
    _assert_equal(second.calls(), 1)
    _assert_equal(calls, 1)

    sandbox_module.clear_resolvers()
end

function _test_nocache_reruns_resolver()
    -- nocache should force the resolver to run every time.
    local sandbox_module = _import_sandbox_module()

    sandbox_module.clear_resolvers()

    local calls = 0

    sandbox_module.add_resolver(function (name, ctx)
        if name == "virtual.nocache" then
            calls = calls + 1
            return ctx.module({
                calls = function ()
                    return calls
                end
            })
        end
        return ctx.miss()
    end)

    local first = import("virtual.nocache", {anonymous = true, nocache = true})
    local second = import("virtual.nocache", {anonymous = true, nocache = true})

    assert(first ~= second)
    _assert_equal(first.calls(), 2)
    _assert_equal(second.calls(), 2)
    _assert_equal(calls, 2)

    sandbox_module.clear_resolvers()
end

function _test_file_result_is_cached_by_logical_name()
    -- File-backed modules should cache by logical module name.
    local sandbox_module = _import_sandbox_module()

    sandbox_module.clear_resolvers()

    local moduledir = path.join(os.tmpdir(), "xmake-test-add-resolver-file-cache")
    local modulefile = path.join(moduledir, "generated", "cached_file.lua")
    local calls = 0

    os.tryrm(moduledir)
    os.mkdir(path.directory(modulefile))

    io.writefile(modulefile, [[
function value()
    return "cached file"
end
]])

    sandbox_module.add_resolver(function (name, ctx)
        if name == "generated.cached_file" then
            calls = calls + 1
            return ctx.file(modulefile)
        end
        return ctx.miss()
    end)

    local first = import("generated.cached_file", {anonymous = true})
    local second = import("generated.cached_file", {anonymous = true})

    assert(first == second)
    _assert_equal(first.value(), "cached file")
    _assert_equal(second.value(), "cached file")
    _assert_equal(calls, 1)

    sandbox_module.clear_resolvers()
    os.tryrm(moduledir)
end

function _test_normal_module_precedence()
    -- Normal modules should win over resolver-backed ones.
    local sandbox_module = _import_sandbox_module()

    sandbox_module.clear_resolvers()

    local moduledir = path.join(os.tmpdir(), "xmake-test-add-resolver-precedence")
    local modulefile = path.join(moduledir, "real", "hello.lua")

    os.tryrm(moduledir)
    os.mkdir(path.directory(modulefile))

    io.writefile(modulefile, [[
function hello()
    return "hello from normal module"
end
]])

    sandbox_module.add_directories(moduledir)

    sandbox_module.add_resolver(function (name, ctx)
        if name == "real.hello" then
            return ctx.module({
                hello = function ()
                    return "hello from resolver"
                end
            })
        end
        return ctx.miss()
    end)

    local mod = import("real.hello", {anonymous = true})
    _assert_equal(mod.hello(), "hello from normal module")

    sandbox_module.clear_resolvers()
    os.tryrm(moduledir)
end

function _test_module_tables_can_use_kind_field()
    -- A normal "kind" field should not get treated specially.
    local sandbox_module = _import_sandbox_module()

    sandbox_module.clear_resolvers()

    sandbox_module.add_resolver(function (name, ctx)
        if name == "virtual.kind_field" then
            return {
                kind = "example",
                value = function ()
                    return "kind field preserved"
                end
            }
        end
        return ctx.miss()
    end)

    local mod = import("virtual.kind_field", {anonymous = true})

    _assert_equal(mod.kind, "example")
    _assert_equal(mod.value(), "kind field preserved")

    sandbox_module.clear_resolvers()
end

function main()
    -- Run the resolver test suite and clean up afterwards.
    _test_module_result()
    _test_file_result()
    _test_string_result_is_file_result()
    _test_raw_table_result_is_module_result()
    _test_miss_falls_through_to_later_resolver()
    _test_nil_falls_through_to_later_resolver()
    _test_cache_reuses_module_result()
    _test_nocache_reruns_resolver()
    _test_file_result_is_cached_by_logical_name()
    _test_normal_module_precedence()
    _test_module_tables_can_use_kind_field()

    _clear_resolvers()
end