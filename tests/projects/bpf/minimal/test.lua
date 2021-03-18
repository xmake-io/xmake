function main(t)
    if is_host("linux") then
        os.vrun("xmake f -p android -vD")
        os.vrun("xmake -vD")
    end
end
