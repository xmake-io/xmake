
function _getinfo(v)
    local info = debug.getinfo(v)
    if info == nil then return end
    if info and info.source:startswith("@") then
        info.fullpath = path.absolute(vformat(info.source:sub(2)), os.workingdir())
        info.path = path.relative(info.fullpath, os.workingdir())
    end
    return info
end

function _getfuncs(funcs_or_filename)
    local funcs = nil
    if type(funcs_or_filename) == "function" then
        funcs = { _getinfo(funcs_or_filename) }
    elseif type(funcs_or_filename) == "table" then
        funcs = {}
        for _, v in ipairs(funcs_or_filename) do
            table.join2(funcs, _getfuncs(v))
        end
    else
        assert(type(funcs_or_filename) == "string")
        funcs_or_filename = path.absolute(funcs_or_filename)
        funcs = {}
        local uplevel = 2
        local func = nil
        repeat
            func = _getinfo(uplevel)
            if func and func.fullpath == funcs_or_filename then
                table.insert(funcs, func)
            end
            uplevel = uplevel + 1
        until func == nil
    end
    return funcs
end

function main(t, message, funcs_or_filename, abort_reason)
    local funcs = _getfuncs(funcs_or_filename)
    cprint(">>     ${red}test failed:${reset} %s", message)
    for _, func in ipairs(funcs) do
        local line = (func.currentline >= 0) and func.currentline or func.linedefined
        local name = (func.func == t.func) and t.funcname or func.name or "(anonymous)"
        cprint(">>       function %s ${underline}%s${reset}:${bright}%d${reset}", name, func.path, line)
    end
    raise("aborting because of ${red}%s${reset} ...", abort_reason or "failed assertion")
end