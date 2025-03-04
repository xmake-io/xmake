function test_workdir(t)
    os.tryrm("build")
    os.tryrm(".xmake")
    os.exec("xmake -P test")
    local outdata = os.iorun("xmake r")
    t:require(outdata)
    t:require(outdata:find("Hello world"))
end
