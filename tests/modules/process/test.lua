import("core.base.process")
import("core.base.scheduler")

local inftimeout = 5000

function test_exit_status_with_timeout(t)
    for _, exitcode in ipairs({0, 42, 0, 42}) do
        local status, errors = os.execv(os.programfile(), {
            "lua", "-c", "os.sleep(100); os.exit(" .. exitcode .. ")"
        }, {try = true, timeout = inftimeout, stdout = os.nuldev(), stderr = os.nuldev()})
        assert(errors ~= "wait process timeout", "missed process exit notification: " .. exitcode)
        t:are_equal(status, exitcode)
    end
end

function test_single_process(t)

    local stdout = os.tmpfile()
    local stderr = os.tmpfile()
    local proc = process.openv("xmake", {"lua", "print", "xmake"}, {stdout = stdout, stderr = stderr})
    proc:wait(inftimeout)
    proc:close()
    t:are_equal(io.readfile(stdout):trim(), "xmake")
end

function test_sched_process(t)

    local count = 0
    local _session = function ()
        local stdout = io.open(os.tmpfile(), 'w')
        local stderr = io.open(os.tmpfile(), 'w')
        local proc = process.openv("xmake", {"lua", "print", "xmake"}, {stdout = stdout, stderr = stderr})
        local ok, status = proc:wait(inftimeout)
        proc:close()
        stdout:close()
        stderr:close()
        count = count + 1
    end
    scheduler.co_group_begin("test", function ()
        for i = 1, 3 do
            scheduler.co_start(_session)
        end
    end)
    scheduler.co_group_wait("test")
    t:are_equal(count, 3)
end
