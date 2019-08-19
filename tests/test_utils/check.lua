

function _tablelength(table)
  local count = 0
  for _ in pairs(table) do count = count + 1 end
  return count
end

function _get_rep(value)
    if type(value) == "nil" then return "(nil)" end
    if type(value) == "string" then return "`" .. value .. "`" end
    return tostring(value)
end

function same(actual, expected)
    if actual ~= actual and expected ~= expected then
        return true, _get_rep(actual), _get_rep(expected)
    end
    return actual == expected, _get_rep(actual), _get_rep(expected)
end

function equal(actual, expected)
    local same, ap, ep = same(actual, expected)
    if same then return true, ap, ep end
    if type(expected) == "table" and type(actual) == "table" then
        local al = _tablelength(actual)
        local el = _tablelength(expected)
        if al ~= el then
            return false, vformat("{...(%d elements)}", al), vformat("{...(%d elements)}", el)
        end
        for k, v in pairs(expected) do
            local av = actual[k]
            local eq, app, epp = equal(av, v)
            if not eq then
                return false, vformat("{[%s] = %s, ...}", k, app), vformat("{[%s] = %s, ...}", k, epp)
            end
        end
        return true, "{...}", "{...}"
    end
    return false, ap, ep
end