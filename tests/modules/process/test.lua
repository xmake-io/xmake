function main()

    -- single process test
    local inftimeout = 5000
    local stdout = os.tmpfile()
    local stderr = os.tmpfile()
    for i = 1, 2 do
        local pro = process.open("echo -n awd", stdout, stderr)
        process.wait(pro, inftimeout)
        process.close(pro)
        assert(io.readfile(stdout) == "awd")
    end

    -- hack test
    local ok = try
    {
        function ()
            process.wait("awd", inftimeout)
            return true
        end
    }
    assert(ok == nil)

    assert(process.close("awd") == nil)

    ok = try
    {
        function ()
            process.waitlist("awd", inftimeout)
            return true
        end
    }
    assert(ok == nil)

    ok = try
    {
        function ()
            process.waitlist({}, inftimeout)
            return true
        end
    }
    assert(ok == nil)

    ok = try
    {
        function ()
            process.waitlist({"awd"}, inftimeout)
            return true
        end
    }
    assert(ok == nil)
end
