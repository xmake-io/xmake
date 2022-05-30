--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        path.lua
--

-- define module: path
local path = path or {}

-- load modules
local string = require("base/string")
local table  = require("base/table")
local _instance = _instance or {}

-- save original interfaces
path._absolute = path._absolute or path.absolute
path._relative = path._relative or path.relative

-- new a path
function _instance.new(p, transform)
    local instance = table.inherit(_instance)
    instance._RAWSTR = p
    instance._TRANSFORM = transform
    setmetatable(instance, _instance)
    table.wrap_lock(instance)
    instance:_update()
    return instance
end

-- update path string
function _instance:_update()
    local transform = self._TRANSFORM
    if transform then
        self._STR = transform(self:rawstr())
    else
        self._STR = self:rawstr()
    end
end

function _instance:str()
    return self._STR
end

function _instance:rawstr()
    return self._RAWSTR
end

function _instance:set(p)
    self._RAWSTR = tostring(p)
    self:_update()
    return self
end

function _instance:transform_set(transform)
    self._TRANSFORM = transform
    self:_update()
    return self
end

function _instance:clone()
    return path.new(self:rawstr(), self._TRANSFORM)
end

function _instance:normalize()
    return path.new(path.normalize(self:str()), self._TRANSFORM)
end

function _instance:translate(opt)
    return path.new(path.translate(self:str(), opt), self._TRANSFORM)
end

function _instance:filename()
    return path.filename(self:str())
end

function _instance:basename()
    return path.basename(self:str())
end

function _instance:extension()
    return path.extension(self:str())
end

function _instance:directory()
    return path.new(path.directory(self:str()), self._TRANSFORM)
end

function _instance:absolute(rootdir)
    return path.new(path.absolute(self:str(), rootdir), self._TRANSFORM)
end

function _instance:relative(rootdir)
    return path.new(path.relative(self:str(), rootdir), self._TRANSFORM)
end

function _instance:join(...)
    local items = {self:str()}
    for _, item in ipairs(table.pack(...)) do
        table.insert(items, tostring(item))
    end
    return path.new(path.join(table.unpack(items)), self._TRANSFORM)
end

function _instance:split()
    return path.split(self:str())
end

function _instance:splitenv()
    return path.splitenv(self:str())
end

-- concat two paths
function _instance:__concat(other)
    if path.instance_of(self) then
        return path.new(path.join(self:str(), tostring(other)), self._TRANSFORM)
    elseif type(self) == "string" then
        return path.new(tostring(other), function (p)
            return self .. p
        end)
    else
        os.raise("cannot concat %s/%s", tostring(self), type(self))
    end
end

-- tostring(path)
function _instance:__tostring()
    return self:str()
end

-- todisplay(path)
function _instance:__todisplay()
    return "<path: " .. self:str() .. ">"
end

-- path.translate:
-- - transform the path separator
-- - expand the user directory with the prefix: ~
-- - remove tail separator
-- - reduce the repeat path separator, "////" => "/"
--
-- path.normalize:
-- - reduce "././" => "."
-- - reduce "/xxx/.." => "/"
--
function path.normalize(p)
    p = tostring(p)
    return path.translate(p, {normalize = true})
end

-- get the directory of the path, compatible with lower version core binary
if not path.directory then
    function path.directory(p, sep)
        p = tostring(p)
        local i =  0
        if sep then
            -- if the path has been normalized, we can quickly find it with a unique path separator prompt
            i = p:lastof(sep, true) or 0
        else
            i = math.max(p:lastof('/', true) or 0, p:lastof('\\', true) or 0)
        end
        if i > 0 then
            if i > 1 then i = i - 1 end
            return p:sub(1, i)
        else
            return "."
        end
    end
end

-- get absolute path
function path.absolute(p, rootdir)
    if rootdir then
        rootdir = tostring(rootdir)
    end
    return path._absolute(tostring(p), rootdir)
end

-- get relative path
function path.relative(p, rootdir)
    if rootdir then
        rootdir = tostring(rootdir)
    end
    return path._relative(tostring(p), rootdir)
end

-- get the filename of the path
function path.filename(p, sep)
    p = tostring(p)
    local i =  0
    if sep then
        -- if the path has been normalized, we can quickly find it with a unique path separator prompt
        i = p:lastof(sep, true) or 0
    else
        i = math.max(p:lastof('/', true) or 0, p:lastof('\\', true) or 0)
    end
    if i > 0 then
        return p:sub(i + 1)
    else
        return p
    end
end

-- get the basename of the path
function path.basename(p)
    p = tostring(p)
    local name = path.filename(p)
    local i = name:lastof(".", true)
    if i then
        return name:sub(1, i - 1)
    else
        return name
    end
end

-- get the file extension of the path: .xxx
function path.extension(p, level)
    p = tostring(p)
    local i = p:lastof(".", true)
    if i then
        local ext = p:sub(i)
        if ext:find("[/\\]") then
            return ""
        end
        if level and level > 1 then
            return path.extension(p:sub(1, i - 1), level - 1) .. ext
        end
        return ext
    else
        return ""
    end
end

-- join path
function path.join(p, ...)
    p = tostring(p)
    return path.translate(p .. path.sep() .. table.concat({...}, path.sep()))
end

-- split path by the separator
function path.split(p)
    p = tostring(p)
    return p:split("[/\\]")
end

-- get the path seperator
function path.sep()
    local sep = path._SEP
    if not sep then
        sep = xmake._FEATURES.path_sep
        path._SEP = sep
    end
    return sep
end

-- get the path seperator of environment variable
function path.envsep()
    local envsep = path._ENVSEP
    if not envsep then
        envsep = xmake._FEATURES.path_envsep
        path._ENVSEP = envsep
    end
    return envsep
end

-- split environment variable with `path.envsep()`,
-- also handles more speical cases such as posix flags and windows quoted paths
function path.splitenv(env_path)
    local result = {}
    if xmake._HOST == "windows" then
        while #env_path > 0 do
            if env_path:startswith(path.envsep()) then
                env_path = env_path:sub(2)
            elseif env_path:startswith('"') then
                -- path quoted with, can contain `;`
                local p_end = env_path:find('"' .. path.envsep(), 2, true) or env_path:find('"$', 2) or (#env_path + 1)
                table.insert(result, env_path:sub(2, p_end - 1))
                env_path = env_path:sub(p_end + 1)
            else
                local p_end = env_path:find(path.envsep(), 2, true) or (#env_path + 1)
                table.insert(result, env_path:sub(1, p_end - 1))
                env_path = env_path:sub(p_end)
            end
        end
    else
        -- see https://git.kernel.org/pub/scm/utils/dash/dash.git/tree/src/exec.c?h=v0.5.9.1&id=afe0e0152e4dc12d84be3c02d6d62b0456d68580#n173
        -- no escape sequences, so `:` and `%` is invalid in environment variable
        for _, v in ipairs(env_path:split(path.envsep(), { plain = true })) do
            -- flag for shells, style `<path>%<flag>`
            local flag = v:find("%", 1, true)
            if flag then
                v = v:sub(1, flag - 1)
            end
            if #v > 0 then
                table.insert(result, v)
            end
        end
    end

    return result
end

-- concat environment variable with `path.envsep()`,
-- also handles more speical cases such as posix flags and windows quoted paths
function path.joinenv(env_table)

    -- check
    if not env_table or #env_table == 0 then
        return ""
    end

    local envsep = path.envsep()
    if xmake._HOST == "windows" then
        local tab = {}
        for _, v in ipairs(env_table) do
            if v ~= "" then
                if v:find(envsep, 1, true) then
                    v = '"' .. v .. '"'
                end
                table.insert(tab, v)
            end
        end
        return table.concat(tab, envsep)
    else
        return table.concat(env_table, envsep)
    end
end

-- the last character is the path seperator?
function path.islastsep(p)
    p = tostring(p)
    local sep = p:sub(#p, #p)
    return xmake._HOST == "windows" and (sep == '\\' or sep == '/') or (sep == '/')
end

-- convert path pattern to a lua pattern
function path.pattern(pattern)

    -- translate wildcards, e.g. *, **
    pattern = pattern:gsub("([%+%.%-%^%$%(%)%%])", "%%%1")
    pattern = pattern:gsub("%*%*", "\001")
    pattern = pattern:gsub("%*", "\002")
    pattern = pattern:gsub("\001", ".*")
    if path.sep() == '\\' then
        pattern = pattern:gsub("\002", "[^/\\]*")
    else
        pattern = pattern:gsub("\002", "[^/]*")
    end

    -- case-insensitive filesystem?
    if not os.fscase() then
        pattern = string.ipattern(pattern, true)
    end
    return pattern
end

-- get cygwin-style path on msys2/cygwin, e.g. "c:\xxx" -> "/c/xxx"
function path.cygwin_path(p)
    p = tostring(p)
    p = p:gsub("\\", "/")
    local pos = p:find(":/")
    if pos == 2 then
        return "/" .. p:sub(1, 1) .. p:sub(3)
    end
    return p
end

-- new a path instance
function path.new(p, transform)
    return _instance.new(p, transform)
end

-- is path instance?
function path.instance_of(p)
    return type(p) == "table" and p.normalize and p._RAWSTR
end

-- register call function
--
-- local p = path("/tmp/a")
-- local p = path("/tmp/a", function (p) return "--key=" .. p end)
setmetatable(path, {
    __call = function (_, ...)
        return path.new(...)
    end,
})

-- return module: path
return path
