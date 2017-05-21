function main()
    -- get mclock
    local tm = os.mclock()
    -- test cpdir
    os.mkdir("test1")
    assert(os.exists("test1"))
    os.cp("test1","test2")
    assert(os.exists("test2"))
    os.rmdir("test1")
    assert(not os.exists("test1"))
    io.writefile("test2/awd","awd")
    os.rmdir("test2")
    assert(not os.exists("test2"))
    -- test rename
    os.mkdir("test1")
    assert(os.exists("test1"))
    os.mv("test1","test2")
    assert(not os.exists("test1"))
    assert(os.exists("test2"))
    os.rmdir("test2")
    assert(not os.exists("test2"))
    -- test cp/mvdir into another dir
    os.mkdir("test1")
    os.mkdir("test2")
    assert(os.exists("test1") and os.exists("test2"))
    os.cp("test1","test2")
    assert(os.exists("test2/test1"))
    os.mv("test1","test2/test1")
    assert(not os.exists("test1"))
    assert(os.exists("test2/test1/test1"))
    os.rmdir("test2")
    assert(not os.exists("test2"))
    -- test setenv
    os.setenv("__AWD","DWA")
    assert(os.getenv("__AWD")=="DWA")
    -- assert mclock
    assert(os.mclock()>=tm)
end
