import("core.base.option")
import("test_utils.test_assert")
import("test_utils.print_error")
import("test_utils.build", { alias = "test_build" })

function main(script)

    if os.isdir(script) then
        script = path.join(script, "test.lua")
    end
    script = path.absolute(script)
    assert(path.filename(script) == "test.lua", "file should named `test.lua`")
    assert(os.isfile(script), "should be a file")

    -- disable statistics
    os.setenv("XMAKE_STATS", "false")

    -- init test context
    local context =
    {
        filename = script
    }
    context = test_assert(context)
    function context:build(argv)
        test_build(argv)
    end

    local root = path.directory(script)

    local verbose = option.get("verbose") or option.get("diagnosis")

    -- trace
    cprint(">> testing %s ...", path.relative(root))

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
    for k, v in pairs(data) do
        if k:startswith("test") and type(v) == "function" then
            if verbose then print(">>     running %s ...", k) end
            context.func = v
            context.funcname = k
            try
            {
                function ()
                    v(context)
                end,
                catch
                {
                    function (error)
                        if not error:find("aborting because of ") then
                            context:print_error(error, v, "unhandled error")
                        else
                            raise(error)
                        end
                    end
                }
            }
            succeed_count = succeed_count + 1
        end
    end
    if verbose then print(">>   finished %d test method(s) ...", succeed_count) end

    -- leave script directory
    os.cd(old_dir)
end
