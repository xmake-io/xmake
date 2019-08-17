
local inftimeout = 5000

function test_single_process(t)

    -- single process test
    local stdout = os.tmpfile()
    local stderr = os.tmpfile()
    for i = 1, 2 do
        local proc = process.open("echo -n awd", {outpath = stdout, errpath = stderr})
        proc:wait(inftimeout)
        proc:close()
        t:are_equal(io.readfile(stdout), "awd")
    end
end

function test_hack(t)

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
