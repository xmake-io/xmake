-- imports
import("core.project.task")
import("core.base.option")

local params = {}

if option.get("quiet") then table.insert(params, "-q") end
if option.get("yes") then table.insert(params, "-y") end
if option.get("verbose") then table.insert(params, "-v") end
if option.get("diagnosis") then table.insert(params, "-D") end

function _run_test(script)

    assert(script:endswith("test.lua"))

    local old_dir = os.cd(os.scriptdir())
    os.execv("xmake", table.join("lua", params, "./runner.lua", script))
    os.cd(old_dir)

end

-- run test with the given name
function _run_test_filter(name)

    local tests = {}

    -- find the test script
    for _, script in ipairs(os.files(path.join(os.scriptdir(), "**", name, "**", "test.lua"))) do
        table.insert(tests, path.absolute(script))
    end
    for _, script in ipairs(os.files(path.join(os.scriptdir(), name, "**", "test.lua"))) do
        table.insert(tests, path.absolute(script))
    end
    for _, script in ipairs(os.files(path.join(os.scriptdir(), "**", name, "test.lua"))) do
        table.insert(tests, path.absolute(script))
    end
    for _, script in ipairs(os.files(path.join(os.scriptdir(), name, "test.lua"))) do
        table.insert(tests, path.absolute(script))
    end

    tests = table.unique(tests)
    if #tests == 0 then
        utils.warning("no test have run, please check your filter .. (%s)", name)
    else
        cprint("> %d test(s) found", #tests)
        if option.get("diagnosis") then
            for _, v in ipairs(tests) do
                cprint(">     %s", v)
            end
        end

        for _, v in ipairs(tests) do
            _run_test(v)
        end
        cprint("> %d test(s) succeed", #tests)
    end
end

-- main entry
function main(name)

    -- run the given test
    return _run_test_filter(name or "/")
end
