function main()
    -- single process test
    local inftimeout=999
    local stdout=os.tmpfile()
    local stderr=os.tmpfile()
    for i = 1, 2 do
        local pro=process.open("echo -n awd",stdout,stderr)
        process.wait(pro,inftimeout)
        process.close(pro)
        assert(io.readfile(stdout)=="awd")
    end
    -- hack test
    local hacked = false
    try{
        function ()
            process.wait("awd",inftimeout)
            hacked = true
        end
    }
    assert(not hacked)
    hacked = (process.close("awd") ~= nil)
    assert(not hacked)
    try{
        function ()
            process.waitlist("awd",inftimeout)
            hacked = true
        end
    }
    assert(not hacked)
    try{
        function ()
            process.waitlist({},inftimeout)
            hacked = true
        end
    }
    assert(not hacked)
    try{
        function ()
            process.waitlist({"awd"},inftimeout)
            hacked = true
        end
    }
    assert(not hacked)
    try{
        function ()
            process.open("thismustnotbeaprogramname")
            hacked = true
        end
    }
    assert(not hacked)
end
