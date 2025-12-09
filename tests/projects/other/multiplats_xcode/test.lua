function main(t)
    if is_host("macosx") then
        os.exec("xmake f -c -vD")
        os.exec("xmake -rvD")
        os.exec("xmake f -c -vD -p iphoneos")
        os.exec("xmake -rvD test_iphoneos")
    end
end
