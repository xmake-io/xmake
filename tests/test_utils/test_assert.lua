
import("print_error")
import("check")

local test_assert = { print_error = print_error.main }

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

function test_assert:are_same(actual, expacted)
    local r, ap, ep = check.same(actual, expacted)
    if not r then
        self:print_error(format("expacted: ${green}%s${reset}, actual ${red}%s${reset}", ep, ap), self.filename)
    end
end

function test_assert:are_not_same(actual, expacted)
    local r, ap, ep = check.same(actual, expacted)
    if r then
        self:print_error(format("expacted: ${green}%s${reset}, actual ${red}%s${reset}", ep, ap), self.filename)
    end
end


function test_assert:are_equal(actual, expacted)
    local r, ap, ep = check.equal(actual, expacted)
    if not r then
        self:print_error(format("expacted: ${green}%s${reset}, actual ${red}%s${reset}", ep, ap), self.filename)
    end
end

function test_assert:are_not_equal(actual, expacted)
    local r, ap, ep = check.equal(actual, expacted)
    if r then
        self:print_error(format("expacted: ${green}%s${reset}, actual ${red}%s${reset}", ep, ap), self.filename)
    end
end

function test_assert:will_raise(func, message_pattern)
    try{
        func,
        finally{
            function (ok, error)
                if ok then
                    self:print_error("expected raise but finined successfully", func)
                elseif message_pattern and not string.find(error, message_pattern) then
                    self:print_error(format("expected raise with message ${green}%s${reset} but got ${red}%s${reset}", message_pattern, error), func)
                end
            end
        }
    }
end

function main(context)
    table.join2(context, test_assert)
    return context
end