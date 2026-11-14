function _run_case(case)
    local workdir = os.tmpfile() .. ".dir"
    try
    {
        function ()
            os.mkdir(workdir)
            os.cp(path.join(os.scriptdir(), "xmake.lua"), path.join(workdir, "xmake.lua"))
            local stdout = path.join(workdir, "stdout.log")
            local stderr = path.join(workdir, "stderr.log")
            local status, errors = os.execv(os.programfile(), {"f", "-y", "--case=" .. case}, {
                try = true,
                timeout = 30000,
                curdir = workdir,
                stdout = stdout,
                stderr = stderr,
                envs = {
                    XMAKE_PROGRAM_DIR = os.programdir(),
                    XMAKE_PROGRAM_FILE = os.programfile(),
                    XMAKE_GLOBALDIR = path.join(workdir, "global"),
                    XMAKE_CONFIGDIR = workdir,
                    XMAKE_STATS = "false"
                }
            })
            local output = case .. "\n" .. (io.readfile(stdout) or "") .. (io.readfile(stderr) or "")
            assert(status ~= nil and errors ~= "wait process timeout", tostring(errors) .. "\n" .. output)
            local succeeds = case:endswith("success") or case == "optional"
            assert((status == 0) == succeeds, output)
            assert(os.isfile(path.join(workdir, "b-installed")) == succeeds, output)
            if not succeeds then
                local message = case:startswith("fetch_") and "expected fetch failure" or "expected install failure"
                if case == "empty_error" then
                    message = "install failed!"
                end
                assert(output:find(message, 1, true), output)
            end
        end,
        finally
        {
            function (ok, errors)
                os.tryrm(workdir)
                if not ok then
                    raise(errors)
                end
            end
        }
    }
end

function main()
    for _, case in ipairs({"dependency", "serial", "empty_error", "fetch_dependency", "fetch_serial",
                           "mixed_serial", "fetch_mixed_serial", "process_dependency", "process_serial",
                           "immediate", "parallel_success", "serial_success", "optional"}) do
        _run_case(case)
    end
end
