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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        path.lua
--

-- define module: path
local path = path or {}

-- load modules
local string = require("base/string")

-- get the directory of the path
function path.directory(p, sep)
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

-- get the filename of the path
function path.filename(p, sep)
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
    local name = path.filename(p)
    local i = name:lastof(".", true)
    if i then
        return name:sub(1, i - 1)
    else
        return name
    end
end

-- get the file extension of the path: .xxx
function path.extension(p)
    local i = p:lastof(".", true)
    if i then
        return p:sub(i)
    else
        return ""
    end
end

-- join path
function path.join(p, ...)
    for _, name in ipairs({...}) do
        p = p .. "/" .. name
    end
    return path.translate(p)
end

-- split path by the separator
function path.split(p)
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
    pattern = pattern:gsub("\002", "[^/]*")

    -- case-insensitive filesystem?
    if not os.fscase() then
        pattern = string.ipattern(pattern, true)
    end
    return pattern
end

-- return module: path
return path
