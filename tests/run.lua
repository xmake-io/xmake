-- imports
import("core.base.task")
import("core.base.option")
import("runner", {rootdir = os.scriptdir()})

function _run_test(script)
    runner(script)
end

-- run test with the given name
function _run_test_filter(name)
    local tests = {}
    local root = path.absolute(os.scriptdir())
    for _, script in ipairs(os.files(path.join(root, "**", name, "**", "test.lua"))) do
        if not script:find(".xmake", 1, true) then
            table.insert(tests, path.absolute(script))
        end
    end
    for _, script in ipairs(os.files(path.join(root, name, "**", "test.lua"))) do
        if not script:find(".xmake", 1, true) then
            table.insert(tests, path.absolute(script))
        end
    end
    for _, script in ipairs(os.files(path.join(root, "**", name, "test.lua"))) do
        table.insert(tests, path.absolute(script))
    end
    for _, script in ipairs(os.files(path.join(root, name, "test.lua"))) do
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

function main(name)
    return _run_test_filter(name or "/")
end
