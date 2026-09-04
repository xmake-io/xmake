-- the minimum version is older than the current xmake version, but its minor
-- number contains two digits, which broke the previous weighted version
-- comparison, e.g. v3.1.1 < v2.12.0
function test_accept_older_minver(t)
    os.iorunv("xmake", {"f", "-c", "-y"})
end

function test_reject_newer_minver(t)
    local tmpdir = path.join(os.tmpdir(), "set_xmakever_newer")
    if os.isdir(tmpdir) then
        os.rmdir(tmpdir)
    end
    os.mkdir(tmpdir)
    local oldir = os.cd(tmpdir)
    io.writefile("xmake.lua", [[
set_xmakever("999.999.999")

target("test")
    set_kind("phony")
]])
    local ok = try { function () os.iorunv("xmake", {"f", "-y"}) end }
    t:require(not ok)
    os.cd(oldir)
    os.rmdir(tmpdir)
end
