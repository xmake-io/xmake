import("core.base.option")
import("test_utils.context", { alias = "test_context" })

function main(script, opt)
    opt = opt or {}

    if os.isdir(script) then
        script = path.join(script, "test.lua")
    end
    script = path.absolute(script)
    assert(path.filename(script) == "test.lua", "file should named `test.lua`")
    assert(os.isfile(script), "should be a file")

    -- disable statistics
    os.setenv("XMAKE_STATS", "false")

    -- init test context
    local context = test_context(script)

    local root = path.directory(script)

    local verbose = true--option.get("verbose") or option.get("diagnosis")

    -- trace
    cprint(">> [%d/%d]: testing %s ...", opt.index, opt.total, path.relative(root))

    -- get test functions
    local data = import("test", { rootdir = root, anonymous = true })

    if data.main then
        -- ignore everthing when we found a main function
        data = { test_main = data.main }
    end

    -- enter script directory
    local old_dir = os.cd(root)

    -- run test
    local succeed_count = 0
    print(data)
    for k, v in pairs(data) do
        if k:startswith("test") and type(v) == "function" then
            if verbose then print(">>     running %s ...", k) end
            context.func = v
            context.funcname = k
            local result = try
            {
                function ()
                    -- set workdir for each test
                    os.cd(root)
                    return v(context)
                end,
                catch
                {
                    function (errors)
                        print(errors, v)
                        if errors then
                            errors = tostring(errors)
                        end
                        if errors and not errors:find("aborting because of ") then
                            context:print_error(errors, v, "unhandled error")
                        else
                            raise(errors)
                        end
                    end
                }
            }
            if context:is_skipped(result) then
                print(">>     skipped %s : %s", k, result.reason)
            end
            succeed_count = succeed_count + 1
        end
    end
    if verbose then print(">>   finished %d test method(s) ...", succeed_count) end

    -- leave script directory
    os.cd(old_dir)
end
