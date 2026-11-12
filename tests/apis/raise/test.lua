function _check(t, scopekind, expected)
    try
    {
        function ()
            os.iorunv(os.programfile(), {"f", "-c"}, {envs = {
                XMAKE_COLORTERM = "nocolor",
                XMAKE_TEST_RAISE_SCOPE = scopekind
            }})
        end,
        finally
        {
            function (ok, errors)
                t:require_not(ok)
                local output = (errors.stdout or "") .. (errors.stderr or "")
                local pos = output:find("error: ", 1, true)
                t:require(pos)
                t:are_equal(output:sub(pos):trim(), expected)
                t:require_not(output:find("unreachable after raise", 1, true))
            end
        }
    }
end

function main(t)
    for _, scopekind in ipairs({"target", "package", "rule", "option", "toolchain", "task"}) do
        _check(t, scopekind, "error: <foo> windows and linux only")
    end
    _check(t, "namespace", "error: <ns::foo> windows and linux only (100%)")
    _check(t, "transition", "error: <foo> windows and linux only")
end
