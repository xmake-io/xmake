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

function test_download_fallback(t)
    local tmpfile = path.join(os.tmpdir(), "test_download_fallback.html")
    os.tryrm(tmpfile)
    -- passing a non-existent tool first should fall back to curl and succeed
    http.download("https://xmake.io", tmpfile, {downloader = {"nonexistent_tool", "curl"}})
    t:require(os.isfile(tmpfile) and os.filesize(tmpfile) > 0)
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
