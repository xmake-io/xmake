function main()
    os.exec("xmake f -c")
    os.exec("xmake")
    if os.host() == "macosx" then
        os.exec("xmake f -p iphoneos")
        os.exec("xmake")
        os.exec("xmake f -p iphoneos -a arm64")
        os.exec("xmake")
    end
end
