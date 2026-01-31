target("test_execv")
    set_kind("phony")
    on_run(function (target)
        print("Testing os.execv with sh:")
        try {
            function ()
                local ok, status = os.execv("sh", {"-c", "exit 1"})
                print("sh returned: ok=" .. tostring(ok) .. ", status=" .. tostring(status))
            end,
            catch {
                function (e)
                    print("sh raised exception: " .. tostring(e))
                end
            }
        }

        print("Testing os.execv with pwsh:")
        try {
            function ()
                local ok, status = os.execv("pwsh", {"-c", "exit 1"})
                print("pwsh returned: ok=" .. tostring(ok) .. ", status=" .. tostring(status))
            end,
            catch {
                function (e)
                    print("pwsh raised exception: " .. tostring(e))
                end
            }
        }
    end)
