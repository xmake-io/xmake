function main(t)
    if is_host("linux") and os.arch() == "x86_64" and linuxos.name() ~= "alpine" then
        os.vrun("xmake f -y -p android -vD")
        os.vrun("xmake -y -vD")
    end
end
