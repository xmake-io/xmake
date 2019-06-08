

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

function same(actual, expacted)
    return actual == expacted, _get_rep(actual), _get_rep(expacted)
end

function equal(actual, expacted)
    local same, ap, ep = same(actual, expacted)
    if same then return true, ap, ep end
    if type(expacted) == "table" and type(actual) == "table" then
        local al = _tablelength(actual)
        local el = _tablelength(expacted)
        if al ~= el then
            return false, vformat("{...(%d elements)}", al), vformat("{...(%d elements)}", el)
        end
        for k, v in pairs(expacted) do
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