function test_msvc_toolset_fallback(t)
    if not is_host("windows") then
        return t:skip("Windows batch environment required")
    end
    -- Keep synthetic Visual Studio environments out of the user's detection cache.
    os.vrunv(os.programfile(), {"lua", path.absolute("check.lua")}, {
        envs = {XMAKE_GLOBALDIR = os.tmpfile() .. "-msvc-global"}
    })
end
