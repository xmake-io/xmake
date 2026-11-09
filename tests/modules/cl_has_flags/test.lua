-- Test cl has_flags: which diagnostics mean "this driver has no such option".
--
-- cl answers that with a command line diagnostic and, for the common case, at exit code
-- 0, so the verdict only exists as text. `warning C5072: ASAN enabled without debug
-- information emission` is not such an answer: cl prints it whenever -fsanitize=address
-- is on a line without a debug-info flag (-Zi/-ZI/-Z7), and once that flag reaches
-- opt.sysflags every probe of every other flag carries it too, which made has_flags()
-- answer false for flags the driver does support.
--
-- The strings below are what cl 19.51 (VS 18.0) printed on a windows-latest runner,
-- captured through private.tools.vstool.iorunv. Patching iorunv out here means this
-- needs no MSVC installation.
--
-- @see https://github.com/xmake-io/xmake/issues/7822

import("core.tools.cl.has_flags")
import("private.tools.vstool")

function test_diagnostics(t)
    local has_flags = import("core.tools.cl.has_flags")
    local vstool = import("private.tools.vstool")

    -- each case is {what cl printed after the filename echo, is the flag supported?}
    local cases = {
        {"", true},
        {"cl : Command line warning D9002 : ignoring unknown option '-xx'", false},
        {"cl : Command line warning D9002 : ignoring unknown option '-std:c++23'", false},
        {"cl : Command line error D8043 : unknown option '-xx'", false},
        -- the code carries the verdict, so a localized cl answers the same way
        {"cl : 命令行 warning D9002 : 忽略未知选项 '-xx'", false},
        -- the diagnostic this check exists for
        {"probe.c : warning C5072: ASAN enabled without debug information emission. Enable debug info for better ASAN error reporting", true},
        -- cl knows the option but not this value: it assumes a default, compiles the stub
        -- and exits 0, so the option itself is supported
        {"cl : Command line warning D9014 : invalid value '5' for '/W'; assuming '1'", true},
        {"cl : Command line warning D9025 : overriding '/W3' with '/W4'", true},
        {"cl : Command line warning D9035 : option 'Og' has been deprecated and will be removed in a future release", true},
        -- the benign warning and the unsupported one together: the latter decides
        {"probe.c : warning C5072: ASAN enabled without debug information emission.\ncl : Command line warning D9002 : ignoring unknown option '-xx'", false},
    }

    local original = vstool.iorunv
    try {
        function ()
            for _, case in ipairs(cases) do
                -- cl echoes the source filename on every compile, -nologo only suppresses
                -- the banner
                vstool.iorunv = function (_, argv)
                    return path.filename(argv[#argv]) .. "\r\n" .. case[1] .. "\r\n"
                end
                t:are_equal(has_flags({"-fsanitize=address"}, {program = "cl", tryrun = true}), case[2])
            end
            -- a non-zero exit never reaches the text scan, iorunv raises first
            vstool.iorunv = function ()
                raise("cl : Command line error D8043 : unknown option '-xx'")
            end
            t:are_equal(not not has_flags({"-fsanitize=address"}, {program = "cl", tryrun = true}), false)
        end,
        finally {function (ok, errors)
            vstool.iorunv = original
            if not ok then raise(errors) end
        end}
    }
end
