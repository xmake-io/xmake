function main(t)
    if is_host("windows", "linux", "macosx") and os.arch():startswith("x") then
        os.vrun("xmake -y")
        os.vrun("xmake run app")
        os.vrun("xmake install -o build/usr")
        os.vrun("./build/usr/app/bin/app" .. (is_host("windows") and ".exe" or ""))
    end
end
