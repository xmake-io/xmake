import("net.http")

function test_download_default(t)
    local tmpfile = path.join(os.tmpdir(), "test_download_default.html")
    os.tryrm(tmpfile)
    http.download("https://xmake.io", tmpfile)
    t:require(os.isfile(tmpfile) and os.filesize(tmpfile) > 0)
    os.tryrm(tmpfile)
end

function test_download_curl(t)
    local tmpfile = path.join(os.tmpdir(), "test_download_curl.html")
    os.tryrm(tmpfile)
    http.download("https://xmake.io", tmpfile, {downloader = "curl"})
    t:require(os.isfile(tmpfile) and os.filesize(tmpfile) > 0)
    os.tryrm(tmpfile)
end

function test_download_aria2(t)
    local tmpfile = path.join(os.tmpdir(), "test_download_aria2.html")
    os.tryrm(tmpfile)
    http.download("https://xmake.io", tmpfile, {downloader = "aria2"})
    t:require(os.isfile(tmpfile) and os.filesize(tmpfile) > 0)
    os.tryrm(tmpfile)
end

function test_download_wget(t)
    local tmpfile = path.join(os.tmpdir(), "test_download_wget.html")
    os.tryrm(tmpfile)
    http.download("https://xmake.io", tmpfile, {downloader = "wget"})
    t:require(os.isfile(tmpfile) and os.filesize(tmpfile) > 0)
    os.tryrm(tmpfile)
end

function test_download_unknown(t)
    local tmpfile = path.join(os.tmpdir(), "test_download_unknown.html")
    os.tryrm(tmpfile)
    local ok = try
    {
        function ()
            http.download("https://xmake.io", tmpfile, {downloader = "nonexistent_tool"})
            return true
        end
    }
    t:require(not ok)
    os.tryrm(tmpfile)
end

function test_download_env(t)
    local tmpfile = path.join(os.tmpdir(), "test_download_env.html")
    os.tryrm(tmpfile)
    local old_env = os.getenv("XMAKE_DOWNLOADER")
    os.setenv("XMAKE_DOWNLOADER", "curl")
    http.download("https://xmake.io", tmpfile)
    os.setenv("XMAKE_DOWNLOADER", old_env)
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
