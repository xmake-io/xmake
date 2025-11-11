function main(t)
    -- freebsd ci is slower
    if is_host("bsd") then
        return
    end
    -- only for x86/x64, because it will take too long time on ci with arm/mips
    if os.subarch():startswith("x") or os.subarch() == "i386" then
        t:build()
    end

    -- test packagekey
    os.execv("xmake", {"lua", "-vD", "utils.ci.packageskey"})
end
