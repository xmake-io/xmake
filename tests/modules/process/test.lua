
local inftimeout = 5000

function test_single_process(t)

    -- single process test
    local stdout = os.tmpfile()
    local stderr = os.tmpfile()
    for i = 1, 2 do
        local pro = process.open("echo -n awd", {outpath = stdout, errpath = stderr})
        process.wait(pro, inftimeout)
        process.close(pro)
        t:are_equal(io.readfile(stdout), "awd")
    end
end

function test_hack(t)
    -- hack test
    t:will_raise(function ()
        process.wait("awd", inftimeout)
    end)

    t:require_not(process.close("awd"))

    t:will_raise(function ()
        process.waitlist("awd", inftimeout)
    end)

    t:will_raise(function ()
        process.waitlist({}, inftimeout)
    end)

    t:will_raise(function ()
        process.waitlist({"awd"}, inftimeout)
    end)
end
