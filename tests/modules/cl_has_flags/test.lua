function test_diagnostics(t)
    local has_flags = import("core.tools.cl.has_flags")
    local vstool = import("private.tools.vstool")
    local warning = "cl : warning C5072: ASAN enabled without debug information emission."
    local unknown = "cl : Command line warning D9002 : ignoring unknown option '-unknown'"
    local original = vstool.iorunv
    try {
        function ()
            for _, case in ipairs({{"", true}, {warning, true}, {"cl : 警告 C5072 : 请启用调试信息", true},
                                    {"test.c(1): warning C4100: unreferenced parameter", true},
                                    {"cl : Command line warning D9025 : overriding '/W3' with '/W4'", true},
                                    {"cl : Command line warning D9026 : options apply to entire command line", true},
                                    {"cl : Command line warning D9028 : minimal rebuild failure, reverting to normal build", true},
                                    {"cl : Command line warning D9035 : option 'Gm' has been deprecated", true},
                                    {"cl : Command line warning D9036 : 'option_2' instead of 'option_1'", true},
                                    {"cl : Command line warning D9014 : invalid value for 'processMax'", false},
                                    {"cl : Command line warning D9040 : ignoring option '/analyze'", false},
                                    {"cl : 命令行 warning D9002 : 忽略未知选项 '-unknown'", false},
                                    {warning .. "\n" .. unknown, false}}) do
                vstool.iorunv = function (_, argv)
                    return path.filename(argv[#argv]) .. "\r\n" .. case[1] .. "\r\n"
                end
                t:are_equal(has_flags({"-fsanitize=address"}, {program = "cl", tryrun = true}), case[2])
            end
            -- A diagnostic ending with the filename is not the filename echo.
            vstool.iorunv = function (_, argv)
                local filename = path.filename(argv[#argv])
                return filename .. "\ncl : Command line warning D9027 : source file ignored: " .. filename
            end
            t:are_equal(has_flags({"-invalid"}, {program = "cl", tryrun = true}), false)
            vstool.iorunv = function () raise("test.c(1): error C2065: undeclared identifier") end
            local supported = has_flags({"-invalid"}, {program = "cl", tryrun = true})
            t:are_equal(not not supported, false)
        end,
        finally {function (ok, errors)
            vstool.iorunv = original
            if not ok then raise(errors) end
        end}
    }
end
