function main(t)
    if is_host("linux") and os.arch() == "x86_64" then
        -- TODO, we need to wait fix of linux kernel
        if linuxos.name() == "archlinux" then
            return
        end
        --[[TODO
        os.vrun("xmake f -y -p android -vD")
        os.vrun("xmake -y -vD")
        ]]
    end
end
