function main(t)
    if is_host("linux") then
        os.vrun("xmake f -y -p android -vD")
        os.vrun("xmake -y -vD")
    end
end
