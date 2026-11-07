import("core.base.process")

function _run_case(t, case, succeeds)
    local workdir = os.tmpfile() .. ".dir"
    local proc
    try
    {
        function ()
            os.mkdir(workdir)
            os.cp(path.join(os.scriptdir(), "xmake.lua"), path.join(workdir, "xmake.lua"))
            local stdout = path.join(workdir, "stdout.log")
            local stderr = path.join(workdir, "stderr.log")
            local envs = os.getenvs()
            envs.XMAKE_PROGRAM_DIR = os.programdir()
            envs.XMAKE_PROGRAM_FILE = os.programfile()
            envs.XMAKE_GLOBALDIR = path.join(workdir, "global")
            envs.XMAKE_CONFIGDIR = workdir
            envs.XMAKE_STATS = "false"
            local envars = {}
            for name, value in pairs(envs) do
                table.insert(envars, name .. "=" .. value)
            end
            proc = process.openv(os.programfile(), {"f", "-y", "--case=" .. case}, {
                curdir = workdir,
                stdout = stdout,
                stderr = stderr,
                envs = envars
            })
            local finished, status = proc:wait(30000)
            if finished ~= 1 then
                proc:kill()
                proc:wait(5000)
            end
            proc:close()
            proc = nil
            local output = (io.readfile(stdout) or "") .. (io.readfile(stderr) or "")
            assert(finished == 1, case .. " timed out\n" .. output)
            if succeeds then
                assert(status == 0, output)
                assert(os.isfile(path.join(workdir, "b-installed")), output)
            else
                assert(status ~= 0, output)
                local message = case:startswith("fetch_") and "expected fetch failure" or "expected install failure"
                if case == "empty_error" then
                    message = "install failed!"
                end
                assert(output:find(message, 1, true), output)
                assert(not os.isfile(path.join(workdir, "b-installed")), output)
            end
        end,
        finally
        {
            function (ok, errors)
                if proc then
                    proc:kill()
                    proc:wait(5000)
                    proc:close()
                end
                os.tryrm(workdir)
                if not ok then
                    raise(errors)
                end
            end
        }
    }
end

function test_install_dependency_failure(t)
    _run_case(t, "dependency")
end

function test_install_serial_failure(t)
    _run_case(t, "serial")
end

function test_install_empty_error(t)
    _run_case(t, "empty_error")
end

function test_fetch_dependency_failure(t)
    _run_case(t, "fetch_dependency")
end

function test_fetch_serial_failure(t)
    _run_case(t, "fetch_serial")
end

function test_parallel_success(t)
    _run_case(t, "parallel_success", true)
end

function test_serial_success(t)
    _run_case(t, "serial_success", true)
end

function test_optional_failure(t)
    _run_case(t, "optional", true)
end
