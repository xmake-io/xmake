local colors  = require("base/colors")
local table   = require("base/table")

local _dump = {}

function _dump._string(str, as_key)
    local quote = (not as_key) or (not str:match("^[a-zA-Z_][a-zA-Z0-9_]*$"))
    if quote then
        io.write(colors.translate("${cyan}\""))
    end
    io.write(colors.translate("${reset}${cyan bright}", false))
    io.write(str)
    io.write(colors.translate("${reset}", false))
    if quote then
        io.write(colors.translate("${cyan}\""))
    end
end

function _dump._keyword(keyword)
    io.write(colors.translate("${blue}" .. tostring(keyword)))
end

function _dump._number(num)
    io.write(colors.translate("${green}" .. num))
end

function _dump._function(func, as_key)
    if as_key then
        return _dump._default(func)
    end
    local funcinfo = debug.getinfo(func)
    local srcinfo = funcinfo.short_src
    if funcinfo.linedefined >= 0 then
        srcinfo = srcinfo .. ":" .. funcinfo.linedefined
    end
    io.write(colors.translate("${red}function ${bright}" .. (funcinfo.name or "") .. "${reset}${dim}" .. srcinfo))
end

function _dump._default(value)
    io.write(colors.translate("${dim}<", false) .. tostring(value) .. colors.translate(">${reset}", false))
end

function _dump._scalar(value, as_key)
    if type(value) == "nil" then
        _dump._keyword("nil")
    elseif type(value) == "boolean" then
        _dump._keyword(value)
    elseif type(value) == "number" then
        _dump._number(value)
    elseif type(value) == "string" then
        _dump._string(value, as_key)
    elseif type(value) == "function" then
        _dump._function(value, as_key)
    else
        _dump._default(value)
    end
end

function _dump._table(value, first_indent, remain_indent)
    io.write(first_indent .. colors.translate("${dim}{"))
    local inner_indent = remain_indent .. "  "
    local is_arr = table.is_array(value)
    local first_value = true
    for k, v in pairs(value) do
        if first_value then
            io.write("\n")
            first_value = false
        else
            io.write(",\n")
        end
        io.write(inner_indent)
        if not is_arr then
            _dump._scalar(k, true)
            io.write(colors.translate("${dim} = "))
        end
        if type(v) == "table" then
            _dump._table(v, "", inner_indent)
        else
            _dump._scalar(v)
        end
    end
    if first_value then
        io.write(colors.translate(" ${dim}}"))
    else
        io.write("\n" .. remain_indent .. colors.translate("${dim}}"))
    end
end

function _dump.main(value, indent)
    indent = indent or ""

    if type(value) == "table" then
        _dump._table(value, indent, indent:gsub(".", " "))
    else
        io.write(indent)
        _dump._scalar(value)
    end
end

return _dump.main