-- This test covers the public project API:
--
--   add_moduleresolver(...)
--
-- The lower-level add_resolver test exercises the resolver engine directly.
-- This file intentionally registers resolvers through the public project API so
-- we know normal xmake.lua authors can use the feature without importing
-- internal modules.

local generatedir = path.join(os.tmpdir(), "xmake-test-add-moduleresolver")
local modulefile = path.join(generatedir, "generated", "hello.lua")


add_moduleresolver(function (name, ctx)
    if name == "generated.public_api" then
        return ctx.file(modulefile)
    end

    if name == "virtual.public_api" then
        return ctx.module({
            hello = function ()
                return "hello from public api module"
            end
        })
    end

    return ctx.miss()
end)

target("test")
    set_kind("phony")

    on_load(function ()
        os.tryrm(generatedir)
        os.mkdir(path.directory(modulefile))

        io.writefile(modulefile, [[
function hello()
    return "hello from generated public api file"
end
]])

        local generated = import("generated.public_api", {anonymous = true})
        assert(generated.hello() == "hello from generated public api file")

        local virtual = import("virtual.public_api", {anonymous = true})
        assert(virtual.hello() == "hello from public api module")
    end)