-- imports
import("core.project.task")

-- run test with the given name
function _run_test(name)

    -- find the test script
    for _, script in ipairs(os.files(path.join(os.scriptdir(), "**", name, "test.lua"))) do

        -- trace
        print("testing %s ...", script)

        -- enter script directory
        os.cd(path.directory(script))

        -- run test
        task.run("lua", {script = path.filename(script)})
        break
    end
end

-- main entry
function main(name)

    -- disable statistics
    os.setenv("XMAKE_STATS", "false")

    -- run the given test
    if name then
        return _run_test(name)
    end

    -- run all tests
    for _, script in ipairs(os.files(path.join(os.scriptdir(), "**", "test.lua"))) do

        -- trace
        print("testing %s ...", script)

        -- enter script directory
        local oldir = os.cd(path.directory(script))

        -- run test
        task.run("lua", {script = path.filename(script)})

        -- leave script directory
        os.cd(oldir)
    end
end
