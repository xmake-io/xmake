import("core.base.global")

function _with_proxy(configs, callback)
    local saved = {}
    for _, name in ipairs({"proxy", "proxy_hosts", "proxy_pac"}) do
        saved[name] = global.get(name)
        global.set(name, configs[name], {force = true})
    end
    try {
        function ()
            callback(import("net.proxy", {anonymous = true, nocache = true}))
        end,
        finally {
            function (ok, errors)
                for _, name in ipairs({"proxy", "proxy_hosts", "proxy_pac"}) do
                    global.set(name, saved[name], {force = true})
                end
                if not ok then
                    raise(errors)
                end
            end
        }
    }
end

function test_proxy_hosts_without_path(t)
    local configured = "http://127.0.0.1:8080"
    _with_proxy({proxy = configured, proxy_hosts = "github.com,gitlab.*,*.xmake.io"}, function (proxy)
        for _, url in ipairs({"https://github.com", "https://github.com:8443",
                              "https://github.com?download=1", "https://github.com#release",
                              "http://gitlab.example", "https://mirror.xmake.io"}) do
            t:are_equal(proxy.config(url), configured)
        end
        t:are_equal(proxy.config("https://example.invalid?next=https://github.com/"), nil)
    end)
end

function test_proxy_hosts_existing_urls(t)
    local configured = "http://127.0.0.1:8080"
    _with_proxy({proxy = configured, proxy_hosts = "github.com,gitlab.*,*.xmake.io"}, function (proxy)
        for _, url in ipairs({"https://github.com/xmake-io/xmake", "https://github.com:8443/file",
                              "https://GITHUB.COM/file", "https://gitlab.example/file",
                              "https://mirror.xmake.io/file", "git@github.com:xmake-io/xmake.git"}) do
            t:are_equal(proxy.config(url), configured)
        end
        t:are_equal(proxy.config("https://example.invalid/file"), nil)
        t:are_equal(proxy.config("https://example.invalid"), nil)
    end)
end

function test_proxy_pac_without_path(t)
    local configured = "http://127.0.0.1:8080"
    local pacfile = os.tmpfile() .. ".lua"
    io.writefile(pacfile, 'function main(url, host) return host == "github.com" or host == "github.com:8443" end')
    try {
        function ()
            _with_proxy({proxy = configured, proxy_pac = pacfile}, function (proxy)
                for _, url in ipairs({"https://github.com", "https://github.com:8443",
                                      "https://github.com?download=1", "https://github.com#release",
                                      "https://github.com/file"}) do
                    t:are_equal(proxy.config(url), configured)
                end
                t:are_equal(proxy.config("https://example.invalid"), nil)
            end)
        end,
        finally {
            function (ok, errors)
                os.rm(pacfile)
                if not ok then
                    raise(errors)
                end
            end
        }
    }
end

function test_unrestricted_proxy(t)
    local configured = "http://127.0.0.1:8080"
    _with_proxy({proxy = configured}, function (proxy)
        t:are_equal(proxy.config("https://github.com"), configured)
        t:are_equal(proxy.config("https://example.invalid/file"), configured)
        t:are_equal(proxy.config(), configured)
    end)
    _with_proxy({}, function (proxy)
        t:are_equal(proxy.config("https://github.com"), nil)
        t:are_equal(proxy.config(), nil)
    end)
end
