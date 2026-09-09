import("net.http")
import("lib.detect.find_tool")

function test_download_default(t)
    local tmpfile = path.join(os.tmpdir(), "test_download_default.html")
    os.tryrm(tmpfile)
    http.download("https://xmake.io", tmpfile)
    t:require(os.isfile(tmpfile) and os.filesize(tmpfile) > 0)
    os.tryrm(tmpfile)
end

function test_download_curl(t)
    if not find_tool("curl") then
        return t:skip("curl not found")
    end
    local tmpfile = path.join(os.tmpdir(), "test_download_curl.html")
    os.tryrm(tmpfile)
    http.download("https://xmake.io", tmpfile, {downloader = "curl"})
    t:require(os.isfile(tmpfile) and os.filesize(tmpfile) > 0)
    os.tryrm(tmpfile)
end

function test_download_aria2(t)
    if not find_tool("aria2") then
        return t:skip("aria2 not found")
    end
    local tmpfile = path.join(os.tmpdir(), "test_download_aria2.html")
    os.tryrm(tmpfile)
    http.download("https://xmake.io", tmpfile, {downloader = "aria2"})
    t:require(os.isfile(tmpfile) and os.filesize(tmpfile) > 0)
    os.tryrm(tmpfile)
end

function test_download_wget(t)
    if not find_tool("wget") then
        return t:skip("wget not found")
    end
    local tmpfile = path.join(os.tmpdir(), "test_download_wget.html")
    os.tryrm(tmpfile)
    http.download("https://xmake.io", tmpfile, {downloader = "wget"})
    t:require(os.isfile(tmpfile) and os.filesize(tmpfile) > 0)
    os.tryrm(tmpfile)
end

function test_download_unknown(t)
    t:will_raise(function ()
        http.download("http://dummy", os.tmpfile(), {downloader = "nonexistent_tool"})
    end, "unknown downloader")
end

function test_download_bad_tool(t)
    t:will_raise(function ()
        http.download("https://xmake.io", os.tmpfile(), {downloader = "nonexistent_tool"})
    end, "unknown downloader")
end

function test_download_bad_url(t)
    if not find_tool("curl") then
        return t:skip("curl not found")
    end
    local tmpfile = os.tmpfile()
    t:will_raise(function ()
        http.download("http://dummy", tmpfile, {downloader = "curl"})
    end)
    os.tryrm(tmpfile)
end

function test_download_env(t)
    if not find_tool("curl") then
        return t:skip("curl not found")
    end
    local tmpfile = path.join(os.tmpdir(), "test_download_env.html")
    os.tryrm(tmpfile)
    local old_env = os.getenv("XMAKE_DOWNLOADER")
    os.setenv("XMAKE_DOWNLOADER", "curl")
    http.download("https://xmake.io", tmpfile)
    os.setenv("XMAKE_DOWNLOADER", old_env)
    t:require(os.isfile(tmpfile) and os.filesize(tmpfile) > 0)
    os.tryrm(tmpfile)
end

function test_download_powershell(t)
    if not is_host("windows") then
        return t:skip("powershell only supported on windows")
    end
    if not find_tool("pwsh") and not find_tool("powershell") then
        return t:skip("powershell not found")
    end
    local tmpfile = path.join(os.tmpdir(), "test_download_powershell.html")
    os.tryrm(tmpfile)
    http.download("https://xmake.io", tmpfile, {downloader = "powershell"})
    t:require(os.isfile(tmpfile) and os.filesize(tmpfile) > 0)
    os.tryrm(tmpfile)
end

function test_download_sourceforge(t)
    local tmpfile = path.join(os.tmpdir(), "rapidxml-1.13.zip")
    os.tryrm(tmpfile)
    http.download("https://sourceforge.net/projects/rapidxml/files/rapidxml/rapidxml%201.13/rapidxml-1.13.zip", tmpfile)
    t:require(os.isfile(tmpfile))
    t:are_equal(hash.sha256(tmpfile), "c3f0b886374981bb20fabcf323d755db4be6dba42064599481da64a85f5b3571")
    os.tryrm(tmpfile)
end
