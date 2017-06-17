--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        tool.lua
--

-- define module
local tool      = tool or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local table     = require("base/table")
local string    = require("base/string")
local filter    = require("base/filter")
local config    = require("project/config")
local global    = require("project/global")
local sandbox   = require("sandbox/sandbox")
local platform  = require("platform/platform")

-- the directories of tools
function tool._directories(name)

    -- the directories
    return  {   path.join(config.directory(), "tools")
            ,   path.join(global.directory(), "tools")
            ,   path.join(xmake._PROGRAM_DIR, "tools")
            }
end

-- match the tool name
function tool._match(name, toolname)

    -- match full? ok
    if name == toolname then return 100 end
 
    -- match the last word? ok
    if name:find(toolname .. "$") then return 80 end

    -- contains it? ok
    if name:find(toolname, 1, true) then return 30 end

    -- not matched
    return 0
end

-- find tool from the given root directory and name
function tool._find(root, name)

    -- attempt to get it directly first
    local filepath = string.format("%s/%s.lua", root, name)
    if os.isfile(filepath) then
        return filepath
    end

    -- make the lower name
    name = name:lower()

    -- remove arguments: -xxx or --xxx
    name = (name:gsub("%s%-+%w+", " "))

    -- get the last name by ' ': xxx xxx toolname
    local names = name:split("%s")
    if #names > 0 then
        name = names[#names]
    end

    -- get the last valid name: xxx-xxx-toolname-5
    local partnames = {}
    for partname in name:gmatch("([%a%+]+)") do
        table.insert(partnames, partname)
    end
    if #partnames > 0 then
        name = partnames[#partnames]
    end

    -- remove suffix: ".xxx"
    name = (name:gsub("%.%w+", ""))

    -- get all tool files
    local file_ok = nil
    local score_maxn = 0
    local files = os.match(string.format("%s/*.lua", root))
    for _, file in ipairs(files) do

        -- the tool name
        local toolname = path.basename(file)

        -- found it?
        if toolname and toolname ~= "tool" then
            
            -- match score
            local score = tool._match(name, toolname:lower()) 

            -- ok?
            if score >= 100 then return file end
    
            -- select the file with the max score
            if score > score_maxn then
                file_ok = file
                score_maxn = score
            end
        end
    end

    -- ok?
    return file_ok
end

-- load the given tool from the given shell name
function tool._load(shellname, kind)

    -- calculate the cache key
    local key = shellname .. (kind or "")

    -- get it directly from cache dirst
    tool._TOOLS = tool._TOOLS or {}
    if tool._TOOLS[key] then
        return tool._TOOLS[key]
    end

    -- find the tool script path
    local toolpath = nil
    local toolname = path.filename(shellname)
    for _, dir in ipairs(tool._directories()) do

        -- find this directory
        toolpath = tool._find(dir, toolname)
        if toolpath then
            break
        end

    end

    -- not exists?
    if not toolpath or not os.isfile(toolpath) then
        return nil, string.format("%s not found!", shellname)
    end

    -- load script
    local script, errors = loadfile(toolpath)
    if script then

        -- make sandbox instance with the given script
        local instance, errors = sandbox.new(script, nil, path.directory(toolpath))
        if not instance then
            return nil, errors
        end

        -- import the tool module
        local module, errors = instance:import()
        if not module then
            return nil, errors
        end

        -- init the tool module
        if module.init then
            module.init(shellname, kind)
        end
    
        -- save tool to the cache
        tool._TOOLS[key] = module

        -- ok?
        return module
    end

    -- failed
    return nil, errors
end

-- check the shellname
function tool._check(shellname, check)

    -- uses the passed checker
    if check ~= nil then

        -- check it
        local ok, errors = sandbox.load(check, shellname) 
        if not ok then
            utils.verror(errors)
        end

        -- ok?
        return ok
    end
 
    -- load the tool module
    local module, errors = tool._load(shellname)
    if not module then
        utils.verror(errors)
    end

    -- no checker? attempt to run it directly
    if not module or not module.check then
        return 0 == os.exec(shellname, os.nuldev(), os.nuldev())
    end

    -- check it
    local ok, errors = sandbox.load(module.check) 
    if not ok then
        utils.verror(errors)
    end

    -- ok?
    return ok
end

-- load the given tool from the given kind
--
-- the kinds:
-- 
-- .e.g cc, cxx, mm, mxx, as, ar, ld, sh, ..
--
function tool.load(kind)

    -- get the shell name 
    local shellname = platform.tool(kind)
    if not shellname then
        return nil, string.format("cannot get tool for %s", kind)
    end
   
    -- load it
    return tool._load(shellname, kind)
end

-- check the tool and return the absolute path if exists
function tool.check(shellname, dirs, check)

    -- check
    assert(shellname)

    -- attempt to get result from cache first
    tool._CHECKINFO = tool._CHECKINFO or {}
    local result = tool._CHECKINFO[shellname]
    if result then
        return result
    end

    -- attempt to check it directly 
    if tool._check(shellname, check) then
        tool._CHECKINFO[shellname] = shellname
        return shellname
    end

    -- attempt to check it from the given directories
    if not path.is_absolute(shellname) then
        for _, dir in ipairs(table.wrap(dirs)) do

            -- the tool path
            local toolpath = path.join(dir, shellname)
            if os.isexec(toolpath) then
            
                -- check it
                if tool._check(toolpath, check) then
                    tool._CHECKINFO[shellname] = toolpath
                    return toolpath
                end
            end
        end
    end
end

-- return module
return tool
