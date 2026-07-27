function _write_plugin(dir, name, text)
    io.writefile(path.join(dir, "xmake.lua"), string.format([[
task("%s")
    set_category("plugin")
    on_run("main")
    set_menu {usage = "xmake %s"}
]], name, name))
    io.writefile(path.join(dir, "main.lua"), string.format([[function main() print("%s") end]], text))
end

function main()
    local global = import("core.base.global")
    local suffix = path.filename(os.tmpfile()):gsub("[^%w]", "")
    local reponame = "plugin-test-repository-" .. suffix
    local hello_name = "plugin-test-hello-" .. suffix
    local formatter_name = "plugin-test-formatter-" .. suffix
    local available_name = "plugin-test-available-" .. suffix
    local local_name = "plugin-test-local-" .. suffix
    local repodir = os.tmpfile() .. ".plugins-repository"
    local localdir = path.join(os.tmpfile() .. ".local-plugin", local_name)
    local plugindir = path.join(global.directory(), "plugins")
    local cachefile = path.join(global.cachedir(), "repository")
    local cachebackup = os.tmpfile() .. ".repository"

    if os.isfile(cachefile) then
        os.cp(cachefile, cachebackup)
    end

    local function cleanup()
        for _, name in ipairs({hello_name, formatter_name, available_name, local_name}) do
            os.tryrm(path.join(plugindir, name))
        end
        if os.isfile(cachebackup) then
            os.cp(cachebackup, cachefile)
        else
            os.tryrm(cachefile)
        end
        os.tryrm(cachebackup)
        os.tryrm(repodir)
        os.tryrm(path.directory(localdir))
    end


    try
    {
        function ()
            -- mock repository with installed and available plugins
            _write_plugin(path.join(repodir, "plugins", hello_name), hello_name, "repo-ok")
            _write_plugin(path.join(repodir, "plugins", formatter_name), formatter_name, "format-ok")
            _write_plugin(path.join(repodir, "plugins", available_name), available_name, "available-ok")
            os.mkdir(path.directory(cachefile))
            local cache = os.isfile(cachefile) and io.load(cachefile) or {}
            cache.repositories = cache.repositories or {}
            cache.repositories[reponame] = {repodir}
            io.save(cachefile, cache)

            -- Feature: install by plain name and repo@name in one invocation
            os.exec("xmake plugin --install " .. hello_name .. " " .. reponame .. "@" .. formatter_name)
            os.exec("xmake " .. hello_name)
            os.exec("xmake " .. formatter_name)

            -- Feature: --list shows installed and available repository plugins
            local out = os.iorun("xmake plugin --list")
            assert(out:find(hello_name, 1, true))
            assert(out:find(formatter_name, 1, true))
            assert(out:find(available_name, 1, true))
            assert(out:find("xmake plugin --install " .. available_name, 1, true))

            -- Feature: install from local directory
            _write_plugin(localdir, local_name, "local-ok")
            os.exec("xmake plugin --install " .. os.args(localdir))
            os.exec("xmake " .. local_name)

            out = os.iorun("xmake plugin --list")
            assert(out:find(local_name, 1, true))

            -- Feature: remove plugin
            os.exec("xmake plugin --remove " .. local_name)
            out = os.iorun("xmake plugin --list")
            assert(not out:find(local_name, 1, true))

            -- Feature: install non-existent plugin fails gracefully
            local ok = try { function () os.exec("xmake plugin --install plugin-test-missing-" .. suffix) end }
            assert(not ok)
            -- Feature: reject plugin name traversal
            ok = try { function () os.exec("xmake plugin --install " .. reponame .. "@..") end }
            assert(not ok)

        end,
        catch
        {
            function (errors)
                cleanup()
                raise(errors)
            end
        },
        finally
        {
            function ()
                cleanup()
            end
        }
    }
end
