function main(t)
    os.cd("libfoo")
    os.exec("xmake package -vD -o ../bar/build")
    os.cd("../bar")
    os.exec("xmake f -c -vD")
    os.exec("xmake -vD")
    os.exec("xmake run")
end
