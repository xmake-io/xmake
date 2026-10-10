import("core.base.bytes")
import("core.base.global")
import("core.base.option")
import("core.base.socket")
import("async.runjobs")
import("lib.detect.find_tool")
import("net.http")

function _download_response(status, verbose)
    local server, port
    for _ = 1, 16 do
        port = math.random(10000, 60000)
        server = try {function () return socket.bind("127.0.0.1", port) end}
        if server then
            break
        end
    end
    assert(server, "cannot bind loopback HTTP test server")
    server:listen(1)
    local outputfile = os.tmpfile()
    local payload = "download response " .. status
    local saved_proxy = global.get("proxy")
    local saved_no_proxy = os.getenv("NO_PROXY")
    local saved_no_proxy_lower = os.getenv("no_proxy")
    global.set("proxy", nil, {force = true})
    os.setenv("NO_PROXY", "127.0.0.1")
    os.setenv("no_proxy", "127.0.0.1")
    option.save()
    option.set("verbose", verbose, {force = true})
    local success, errors, contents
    try {
        function ()
            runjobs("http-download-response", function (index)
                if index == 1 then
                    success = try {
                        function ()
                            http.download("http://127.0.0.1:" .. port .. "/response", outputfile,
                                          {downloader = "curl", timeout = 5})
                            return true
                        end,
                        catch {function (errs) errors = tostring(errs) end}
                    }
                else
                    local client = assert(server:accept({timeout = 5000}), "no HTTP client")
                    try {
                        function ()
                            local request = ""
                            local buffer = bytes(4096)
                            while not request:find("\r\n\r\n", 1, true) do
                                local received, data = client:recv(buffer)
                                if received > 0 then
                                    request = request .. data:str()
                                    assert(#request <= 8192, "HTTP request too large")
                                else
                                    assert(received == 0 and client:wait(socket.EV_RECV, 5000) == socket.EV_RECV,
                                           "HTTP request receive failed")
                                end
                            end
                            local response = "HTTP/1.1 " .. status .. " Test Response\r\nContent-Length: " .. #payload
                                             .. "\r\nConnection: close\r\n\r\n" .. payload
                            client:send(response, {block = true})
                        end,
                        finally {
                            function (ok, errs)
                                client:close()
                                if not ok then
                                    raise(errs)
                                end
                            end
                        }
                    }
                end
            end, {total = 2, comax = 2})
            if os.isfile(outputfile) then
                contents = io.readfile(outputfile)
            end
        end,
        finally {
            function (ok, errs)
                option.restore()
                global.set("proxy", saved_proxy, {force = true})
                os.setenv("NO_PROXY", saved_no_proxy)
                os.setenv("no_proxy", saved_no_proxy_lower)
                server:close()
                os.tryrm(outputfile)
                if not ok then
                    raise(errs)
                end
            end
        }
    }
    return success == true, errors, contents, payload
end

function test_curl_http_errors(t)
    if not find_tool("curl") then
        return t:skip("curl not found")
    end
    local results = {}
    for _, status in ipairs({404, 500}) do
        for _, verbose in ipairs({false, true}) do
            local success, errors = _download_response(status, verbose)
            print("HTTP %d verbose=%s success=%s", status, tostring(verbose), tostring(success))
            table.insert(results, {success = success, errors = errors})
        end
    end
    for _, result in ipairs(results) do
        t:are_equal(result.success, false)
        t:require(result.errors and result.errors:find("22", 1, true))
    end
end

function test_curl_http_success(t)
    if not find_tool("curl") then
        return t:skip("curl not found")
    end
    for _, verbose in ipairs({false, true}) do
        local success, errors, contents, payload = _download_response(200, verbose)
        t:are_equal(success, true)
        t:are_equal(errors, nil)
        t:are_equal(contents, payload)
    end
end
