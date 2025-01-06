function main()
    os.exec("xmake task0")
    os.exec("xmake ns1::task1")
    os.exec("xmake ns1::ns2::task2")
end
