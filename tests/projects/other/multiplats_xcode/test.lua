function main(t)
    if is_host("macosx") then
        os.exec("xmake f -c -vD")
        os.exec("xmake -rvD")
    end
end
