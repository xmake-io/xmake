function main(t)
    if (os.subarch():startswith("x") or os.subarch() == "i386") and not is_host("bsd", "solaris") then
        os.cd("libfoo")
        os.exec("xmake package -D -o ../bar/build")
        os.cd("../bar")
        os.exec("xmake f -c -D")
        os.exec("xmake -D")
        os.exec("xmake run")
    end
end
