--!A cross-toolchain build utility based on Lua
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
-- @file        toolchain.lua
--

-- define module
local toolchain      = toolchain or {}
local _instance     = _instance or {}

-- load modules
local os             = require("base/os")
local path           = require("base/path")
local utils          = require("base/utils")
local table          = require("base/table")
local global         = require("base/global")
local option         = require("base/option")
local interpreter    = require("base/interpreter")
local config         = require("project/config")
local language       = require("language/language")
local sandbox        = require("sandbox/sandbox")
local sandbox_module = require("sandbox/modules/import/core/sandbox/module")

-- new an instance
function _instance.new(name, info, rootdir)
    local instance    = table.inherit(_instance)
    instance._NAME    = name
    instance._INFO    = info
    instance._ROOTDIR = rootdir
    return instance
end

-- get toolchain name
function _instance:name()
    return self._NAME
end

-- set the value to the toolchain configuration
function _instance:set(name, ...)
    self._INFO:apival_set(name, ...)
end

-- add the value to the toolchain configuration
function _instance:add(name, ...)
    self._INFO:apival_add(name, ...)
end

-- get the toolchain configuration
function _instance:get(name)

    -- attempt to get the static configure value
    local value = self._INFO:get(name)
    if value ~= nil then
        return value
    end

    -- lazy loading platform 
    self:_load()

    -- get other platform info
    return self._INFO:get(name)
end

-- get toolchain kind
function _instance:kind()
    return self._INFO:get("kind")
end

-- is standalone toolchain?
function _instance:standalone()
    return self:kind() == "standalone"
end

-- get the program and name of the given tool kind
function _instance:tool(toolkind)
    local toolpathes = self:get("toolsets." .. toolkind)
    if toolpathes then
        for _, toolpath in ipairs(table.wrap(toolpathes)) do
            local program, toolname = self:_checktool(toolkind, toolpath)
            if program then
                return program, toolname
            end
        end
    end
end

-- get the toolchain script
function _instance:script(name)
    return self._INFO:get(name)
end

-- get the bin directory
function _instance:bindir()
    return config.get("bin") or self:get("bindir")
end

-- get the sdk directory
function _instance:sdkdir()
    return config.get("sdk") or self:get("sdkdir")
end

-- do load 
function _instance:_load()
    if not self._LOADED then
        local on_load = self._INFO:get("load")
        if on_load then
            local ok, errors = sandbox.load(on_load, self)
            if not ok then
                os.raise(errors)
            end
        end
        self._LOADED = true
    end
end

-- do check 
function _instance:check()
    local checkok = true
    if not self._CHECKED then
        local on_check = self._INFO:get("check")
        if on_check then
            local ok, results_or_errors = sandbox.load(on_check, self)
            if ok then
                checkok = results_or_errors
            else
                os.raise(results_or_errors)
            end
        end
        self._CHECKED = true
    end
    return checkok
end

-- get the tool description from the tool kind
function _instance:_description(toolkind)
    local descriptions = self._DESCRIPTIONS
    if not descriptions then
        descriptions = 
        {
            cc         = "the c compiler",
            cxx        = "the c++ compiler",
            ld         = "the linker",
            sh         = "the shared library linker",
            ar         = "the static library archiver",
            ex         = "the static library extractor",
            strip      = "the symbols stripper",
            dsymutil   = "the symbols generator",
            mm         = "the objc compiler",
            mxx        = "the objc++ compiler",
            as         = "the assember",
            sc         = "the swift compiler",
            scld       = "the swift linker",
            scsh       = "the swift shared library linker",
            gc         = "the golang compiler",
            gcld       = "the golang linker",
            gcar       = "the golang static library archiver",
            dc         = "the dlang compiler",
            dcld       = "the dlang linker",
            dcsh       = "the dlang shared library linker",
            dcar       = "the dlang static library archiver",
            rc         = "the rust compiler",
            rcld       = "the rust linker",
            rcsh       = "the rust shared library linker",
            rcar       = "the rust static library archiver",
            cu         = "the cuda compiler",
            culd       = "the cuda linker",
            cuccbin    = "the cuda host c++ compiler",
        }
        self._DESCRIPTIONS = descriptions
    end
    return descriptions[toolkind]
end

-- check the given tool path
function _instance:_checktool(toolkind, toolpath)

    -- get find_tool
    local find_tool = self._find_tool
    if not find_tool then
        find_tool = sandbox_module.import("lib.detect.find_tool", {anonymous = true})
        self._find_tool = find_tool
    end

    -- do filter for toolpath variables, e.g. set_toolsets("cc", "$(env CC)")
    local sandbox_inst = sandbox.instance()
    if sandbox_inst then
        local filter = sandbox_inst:filter()
        if filter then
            local value = filter:handle(toolpath)
            if value and value:trim() ~= "" then
                toolpath = value
            else
                return
            end
        end
    end

    -- find tool program
    local program, toolname
    local tool = find_tool(toolpath, {program = toolpath, pathes = self:bindir()})
    if tool then
        program = tool.program
        toolname = tool.name
    end

    -- get tool description from the tool kind
    local description = self:_description(toolkind) or ("unknown toolkind " .. toolkind)

    -- trace
    if option.get("verbose") then
        if program then
            utils.cprint("${dim}checking for %s (%s) ... ${color.success}%s", description, toolkind, path.filename(program))
        else
            utils.cprint("${dim}checking for %s (%s: ${bright}%s${clear}) ... ${color.nothing}${text.nothing}", description, toolkind, toolpath)
        end
    end
    return program, toolname
end

-- the interpreter
function toolchain._interpreter()

    -- the interpreter has been initialized? return it directly
    if toolchain._INTERPRETER then
        return toolchain._INTERPRETER
    end

    -- init interpreter
    local interp = interpreter.new()
    assert(interp)
 
    -- define apis
    interp:api_define(toolchain._apis())

    -- define apis for language
    interp:api_define(language.apis())
    
    -- save interpreter
    toolchain._INTERPRETER = interp

    -- ok?
    return interp
end

-- get toolchain apis
function toolchain._apis()
    return 
    {
        values = 
        {
            "toolchain.set_kind"
        ,   "toolchain.set_bindir"
        ,   "toolchain.set_sdkdir"
        }
    ,   keyvalues =
        {
            -- toolchain.set_xxx
            "toolchain.set_toolsets"
            -- toolchain.add_xxx
        ,   "toolchain.add_runenvs"
        }
    ,   script =
        {
            -- toolchain.on_xxx
            "toolchain.on_load"
        ,   "toolchain.on_check"
        }
    ,   dictionary =
        {
            -- toolchain.set_xxx
            "toolchain.set_formats"
        }
    }
end

-- get toolchain directories
function toolchain.directories()

    -- init directories
    local dirs = toolchain._DIRS or {   path.join(global.directory(), "toolchains")
                                    ,   path.join(os.programdir(), "toolchains")
                                    }
                                
    -- save directories to cache
    toolchain._DIRS = dirs
    return dirs
end

-- load the given toolchain 
function toolchain.load(name, plat)

    -- get toolchain name
    plat = plat or config.get("plat") or os.host()
    if not plat then
        return nil, string.format("unknown toolchain!")
    end

    -- get cache key
    local cachekey = name .. "_" .. plat .. "_" .. (config.get("arch") or os.arch())

    -- get it directly from cache dirst
    toolchain._TOOLCHAINS = toolchain._TOOLCHAINS or {}
    if toolchain._TOOLCHAINS[cachekey] then
        return toolchain._TOOLCHAINS[cachekey]
    end

    -- find the toolchain script path
    local scriptpath = nil
    for _, dir in ipairs(toolchain.directories()) do
        scriptpath = path.join(dir, name, "xmake.lua")
        if os.isfile(scriptpath) then
            break
        end
    end
    if not scriptpath or not os.isfile(scriptpath) then
        return nil, string.format("the toolchain %s not found!", name)
    end

    -- get interpreter
    local interp = toolchain._interpreter()

    -- load script
    local ok, errors = interp:load(scriptpath)
    if not ok then
        return nil, errors
    end

    -- load toolchain
    local results, errors = interp:make("toolchain", true, false)
    if not results and os.isfile(scriptpath) then
        return nil, errors
    end

    -- check the toolchain name
    local result = results[name]
    if not result then
        return nil, string.format("the toolchain %s not found!", name)
    end

    -- new an instance
    local instance, errors = _instance.new(name, result, interp:rootdir())
    if not instance then
        return nil, errors
    end

    -- save instance to the cache
    toolchain._TOOLCHAINS[cachekey] = instance
    return instance
end

-- return module
return toolchain
