
function main(t, message, funcs_or_filename, abort_reason)
    local funcs = nil
    if type(funcs_or_filename) == "function" then
        funcs = { debug.getinfo(funcs_or_filename) }
    elseif type(funcs_or_filename) == "table" then
        funcs = {}
        for _, v in ipairs(funcs_or_filename) do
            table.insert(funcs, debug.getinfo(v))
        end
    else
        assert(type(funcs_or_filename) == "string")
        funcs = {}
        local uplevel = 2
        local func = nil
        repeat
            func = debug.getinfo(uplevel)
            if (func and func.source:endswith(funcs_or_filename)) then
                table.insert(funcs, func)
            end
            uplevel = uplevel + 1
        until func == nil
    end
    cprint(">>     ${red}test failed:${reset} %s", message)
    for _, func in ipairs(funcs) do
        local line = (func.currentline >= 0) and func.currentline or func.linedefined
        local name = (func.func == t.func) and t.funcname or func.name or "(anonymous)"
        cprint(">>       function %s ${underline}%s${reset}:${bright}%d${reset}", name, func.source, line)
    end
    raise("aborting because of ${red}%s${reset} ...", abort_reason or "failed assertion")
end