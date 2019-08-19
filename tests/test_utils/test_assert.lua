

import("check")

local test_assert = { print_error = import("print_error", { anonymous = true }).main }

function test_assert:require(value)
    if not value then
        self:print_error(vformat("require ${green}true${reset} but got ${red}%s${reset}", value), self.filename)
    end
end

function test_assert:require_not(value)
    if value then
        self:print_error(vformat("require ${green}false${reset} but got ${red}%s${reset}", value), self.filename)
    end
end

function test_assert:are_same(actual, expected)
    local r, ap, ep = check.same(actual, expected)
    if not r then
        self:print_error(format("expected: ${green}%s${reset}, actual ${red}%s${reset}", ep, ap), self.filename)
    end
end

function test_assert:are_not_same(actual, expected)
    local r, ap, ep = check.same(actual, expected)
    if r then
        self:print_error(format("expected: ${green}%s${reset}, actual ${red}%s${reset}", ep, ap), self.filename)
    end
end


function test_assert:are_equal(actual, expected)
    local r, ap, ep = check.equal(actual, expected)
    if not r then
        self:print_error(format("expected: ${green}%s${reset}, actual ${red}%s${reset}", ep, ap), self.filename)
    end
end

function test_assert:are_not_equal(actual, expected)
    local r, ap, ep = check.equal(actual, expected)
    if r then
        self:print_error(format("expected: ${green}%s${reset}, actual ${red}%s${reset}", ep, ap), self.filename)
    end
end

test_assert._will_raise_stack = {}
function test_assert:will_raise(func, message_pattern)
    table.insert(self._will_raise_stack, 1, debug.getinfo(2).func)
    try
    {
        func,
        finally
        {
            function (ok, error)
                local funcs = { func, unpack(self._will_raise_stack) }
                if ok then
                    self:print_error("expected raise but finished successfully", funcs)
                elseif message_pattern and not error:find(message_pattern, 1, true) and not error:find(message_pattern) then
                    self:print_error(format("expected raise with message ${green}%s${reset} but got ${red}%s${reset}", message_pattern, error), funcs)
                end
            end
        }
    }
    table.remove(self._will_raise_stack, 1)
end

function main()
    return test_assert
end
