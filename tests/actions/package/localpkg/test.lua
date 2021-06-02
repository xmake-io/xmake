function main(t)
    if (os.subarch():startswith("x") or os.subarch() == "i386") and not is_host("bsd") then
        os.cd("libfoo")
        os.exec("xmake package -vD -o ../bar/build")
        os.cd("../bar")
        os.exec("xmake f -c -vD")
        os.exec("xmake -vD")
        os.exec("xmake run")
    end
end
