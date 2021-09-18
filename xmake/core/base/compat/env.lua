-- (c) 2012 David Manura.  Licensed under the same terms as Lua 5.1/5.2 (MIT license).
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
-- @author      David Manura, ruki
-- @file        env.lua
--

-- define module: env
local env = env or {}

-- from https://github.com/davidm/lua-inspect/blob/master/lib/luainspect/compat_env.lua
if _G.setfenv then -- Lua 5.1
    env.setfenv = _G.setfenv
    env.getfenv = _G.getfenv
else -- >= Lua 5.2
    -- helper function for `getfenv`/`setfenv`
    local function envlookup(f)
        local name, val
        local up = 0
        local unknown
        repeat
            up = up + 1; name, val = debug.getupvalue(f, up)
            if name == '' then unknown = true end
        until name == '_ENV' or name == nil
        if name ~= '_ENV' then
            up = nil
            if unknown then error("upvalues not readable in Lua 5.2 when debug info missing", 3) end
        end
        return (name == '_ENV') and up, val, unknown
    end

    -- helper function for `getfenv`/`setfenv`
    local function envhelper(f, name)
        if type(f) == 'number' then
            if f < 0 then
                error(("bad argument #1 to '%s' (level must be non-negative)"):format(name), 3)
            elseif f < 1 then
                error("thread environments unsupported in Lua 5.2", 3) --[*]
            end
            f = debug.getinfo(f+2, 'f').func
        elseif type(f) ~= 'function' then
            error(("bad argument #1 to '%s' (number expected, got %s)"):format(type(name, f)), 2)
        end
        return f
    end
    -- [*] might simulate with table keyed by coroutine.running()

    -- 5.1 style `setfenv` implemented in 5.2
    function env.setfenv(f, t)
        local f = envhelper(f, 'setfenv')
        local up, val, unknown = envlookup(f)
        if up then
            debug.upvaluejoin(f, up, function() return up end, 1) -- unique upvalue [*]
            debug.setupvalue(f, up, t)
        else
            local what = debug.getinfo(f, 'S').what
            if what ~= 'Lua' and what ~= 'main' then -- not Lua func
                error("'setfenv' cannot change environment of given object", 2)
            end -- else ignore no _ENV upvalue (warning: incompatible with 5.1)
        end
    end
    -- [*] http://lua-users.org/lists/lua-l/2010-06/msg00313.html

    -- 5.1 style `getfenv` implemented in 5.2
    function env.getfenv(f)
        if f == 0 or f == nil then return _G end -- simulated behavior
        local f = envhelper(f, 'setfenv')
        local up, val = envlookup(f)
        if not up then return _G end -- simulated behavior [**]
        return val
    end
    -- [**] possible reasons: no _ENV upvalue, C function

    -- register to global
    _G.setfenv = env.setfenv
    _G.getfenv = env.getfenv
    debug.setfenv = env.setfenv
    debug.getfenv = env.getfenv
end

-- return module: env
return env
