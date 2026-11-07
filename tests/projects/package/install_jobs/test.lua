function _check_events(workdir, case, limit)
    local active = {fetch = {}, install = {}}
    local finished = {fetch = {}, install = {}}
    local maximum = {fetch = 0, install = 0}
    local starts = {fetch = {}, install = {}}
    local deps = {jobs_b = {"jobs_a"}, jobs_c = {"jobs_a"}, jobs_d = {"jobs_b", "jobs_c"}}
    for _, line in ipairs(io.readfile(path.join(workdir, "events.log")):split("\n", {plain = true})) do
        local phase, event, name = line:match("(%S+) (%S+) (%S+)")
        if phase then
            if event == "start" then
                assert(not active[phase][name], line)
                if case == "diamond" then
                    for _, dep in ipairs(deps[name]) do
                        assert(finished[phase][dep], line .. " before " .. dep)
                    end
                elseif case == "mixed" then
                    assert(not active[phase].jobs_c, line)
                    if name == "jobs_c" then
                        assert(#table.keys(active[phase]) == 0, line)
                    end
                end
                active[phase][name] = true
                starts[phase][name] = (starts[phase][name] or 0) + 1
                local count = #table.keys(active[phase])
                assert(count <= limit, line)
                maximum[phase] = math.max(maximum[phase], count)
            else
                assert(active[phase][name], line)
                active[phase][name] = nil
                finished[phase][name] = true
            end
        end
    end
    for _, phase in ipairs({"fetch", "install"}) do
        assert(#table.keys(active[phase]) == 0, phase)
        local count = (case:startswith("group") or case == "installed") and phase == "install" and 5 or 6
        assert(#table.keys(finished[phase]) == count, phase .. " " .. case)
        if case == "parallel" then
            assert(maximum[phase] == limit, phase .. " parallelism changed")
        elseif case:startswith("group") and phase == "install" then
            assert((starts[phase].jobs_a or 0) + (starts[phase].jobs_b or 0) == 1)
        elseif case == "schemes" and phase == "install" then
            assert(starts[phase].jobs_a == 2)
            assert(os.isfile(path.join(workdir, "scheme-first")))
            assert(os.isfile(path.join(workdir, "scheme-second")))
        end
    end
end

function _run_case(case, verbose)
    local workdir = os.tmpfile() .. ".dir"
    try
    {
        function ()
            os.mkdir(workdir)
            for _, name in ipairs({"xmake.lua", "events.lua"}) do
                os.cp(path.join(os.scriptdir(), name), path.join(workdir, name))
            end
            local stdout = path.join(workdir, "stdout.log")
            local stderr = path.join(workdir, "stderr.log")
            local argv = {"f", "-y", "--case=" .. case}
            if verbose then
                table.insert(argv, "-" .. verbose)
            end
            local status, errors = os.execv(os.programfile(), argv, {
                try = true, timeout = 30000, curdir = workdir, stdout = stdout, stderr = stderr,
                envs = {
                    XMAKE_PROGRAM_DIR = os.programdir(), XMAKE_PROGRAM_FILE = os.programfile(),
                    XMAKE_GLOBALDIR = path.join(workdir, "global"), XMAKE_CONFIGDIR = workdir, XMAKE_STATS = "false"
                }
            })
            local output = case .. "\n" .. (io.readfile(stdout) or "") .. (io.readfile(stderr) or "")
            assert(status == 0, tostring(errors) .. "\n" .. output)
            _check_events(workdir, case, (verbose or case == "serial") and 1 or 4)
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
    for _, case in ipairs({"parallel", "serial", "mixed", "diamond", "group", "group_failure", "schemes", "optional", "installed"}) do
        _run_case(case)
    end
    _run_case("parallel", "v")
    _run_case("parallel", "vD")
end
