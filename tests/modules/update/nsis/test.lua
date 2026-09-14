import("private.action.update.nsis")

-- Match xmake/scripts/run.vbs: quote an argv only when it contains a space.
function _vbs_shell_execute_args(params)
    local parts = {}
    for _, p in ipairs(params) do
        if p:find(" ", 1, true) then
            table.insert(parts, '"' .. p .. '"')
        else
            table.insert(parts, p)
        end
    end
    return table.concat(parts, " ")
end

function test_installdir_params_keeps_spaces_unquoted(t)
    local params = nsis.installdir_params("C:\\Program Files\\xmake")
    t:are_equal(_vbs_shell_execute_args(params), "/D=C:\\Program Files\\xmake")
end

function test_installdir_params_plain_path(t)
    local params = nsis.installdir_params("C:\\xmake")
    t:are_equal(#params, 1)
    t:are_equal(params[1], "/D=C:\\xmake")
    t:are_equal(_vbs_shell_execute_args(params), "/D=C:\\xmake")
end
