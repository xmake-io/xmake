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
function _instance.new(name, info, plat, arch)
    local instance    = table.inherit(_instance)
    instance._NAME    = name
    instance._INFO    = info
    instance._PLAT    = plat
    instance._ARCH    = arch
    return instance
end

-- get toolchain name
function _instance:name()
    return self._NAME
end

-- get toolchain platform
function _instance:plat()
    return self._PLAT
end

-- get toolchain architecture
function _instance:arch()
    return self._ARCH
end

-- the current platform is belong to the given platforms?
function _instance:is_plat(...)
    local plat = self:plat()
    for _, v in ipairs(table.join(...)) do
        if v and plat == v then
            return true
        end
    end
end

-- the current architecture is belong to the given architectures?
function _instance:is_arch(...)
    local arch = self:arch()
    for _, v in ipairs(table.join(...)) do
        if v and arch:find("^" .. v:gsub("%-", "%%-") .. "$") then
            return true
        end
    end
end

-- get toolchain info
function _instance:info()
    local arch = self:arch()
    local infos = self._INFOS
    if not infos then
        infos = {}
        self._INFOS = infos
    end
    local info = infos[arch]
    if not info then
        -- we need multiple info objects for different architectures
        info = self._INFO:clone()
        infos[arch] = info
    end
    return info
end

-- set the value to the toolchain configuration
function _instance:set(name, ...)
    self:info():apival_set(name, ...)
end

-- add the value to the toolchain configuration
function _instance:add(name, ...)
    self:info():apival_add(name, ...)
end

-- get the toolchain configuration
function _instance:get(name)

    -- attempt to get the static configure value
    local value = self:info():get(name)
    if value ~= nil then
        return value
    end

    -- lazy loading platform
    self:_load()

    -- get other platform info
    return self:info():get(name)
end

-- get toolchain kind
function _instance:kind()
    return self:info():get("kind")
end

-- is standalone toolchain?
function _instance:standalone()
    return self:kind() == "standalone"
end

-- get the run environments
function _instance:runenvs()
    local runenvs = self._RUNENVS
    if runenvs == nil then
        local toolchain_runenvs = self:get("runenvs")
        if toolchain_runenvs then
            runenvs = {}
            for name, values in pairs(toolchain_runenvs) do
                if type(values) == "table" then
                    values = path.joinenv(values)
                end
                runenvs[name] = values
            end
        end
        runenvs = runenvs or false
        self._RUNENVS = runenvs
    end
    return runenvs or nil
end

-- get the program and name of the given tool kind
function _instance:tool(toolkind)
    local toolpaths = self:get("toolset." .. toolkind)
    if toolpaths then
        for _, toolpath in ipairs(table.wrap(toolpaths)) do
            local program, toolname = self:_checktool(toolkind, toolpath)
            if program then
                return program, toolname
            end
        end
    end
end

-- get the toolchain script
function _instance:script(name)
    return self:info():get(name)
end

-- get the bin directory
function _instance:bindir()
    return config.get("bin") or self:get("bindir")
end

-- get the sdk directory
function _instance:sdkdir()
    return config.get("sdk") or self:get("sdkdir")
end

-- do check, we only check it once for all architectures
function _instance:check()
    local checkok = true
    if not self._CHECKED then
        local on_check = self:info():get("check")
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

-- do load, @note we need load it repeatly for each architectures
function _instance:_load()
    local info = self:info()
    if not info:get("__loaded") and not info:get("__loading") then
        local on_load = info:get("load")
        if on_load then
            info:set("__loading", true)
            local ok, errors = sandbox.load(on_load, self)
            info:set("__loading", false)
            if not ok then
                os.raise(errors)
            end
        end
        info:set("__loaded", true)
    end
end

-- get the tool description from the tool kind
function _instance:_description(toolkind)
    local descriptions = self._DESCRIPTIONS
    if not descriptions then
        descriptions =
        {
            cc         = "the c compiler",
            cxx        = "the c++ compiler",
            cpp        = "the c/c++ preprocessor",
            ld         = "the linker",
            sh         = "the shared library linker",
            ar         = "the static library archiver",
            ex         = "the static library extractor",
            mrc        = "the windows resource compiler",
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
            fc         = "the fortran compiler",
            fcld       = "the fortran linker",
            fcsh       = "the fortran shared library linker",
            zc         = "the zig compiler",
            zcld       = "the zig linker",
            zcsh       = "the zig shared library linker",
            zcar       = "the zig static library archiver",
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

    -- do filter for toolpath variables, e.g. set_toolset("cc", "$(env CC)")
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
    local tool = find_tool(toolpath, {program = toolpath, paths = self:bindir(), envs = self:get("runenvs")})
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
    interp:api_define(toolchain.apis())

    -- define apis for language
    interp:api_define(language.apis())

    -- save interpreter
    toolchain._INTERPRETER = interp

    -- ok?
    return interp
end

-- get toolchain apis
function toolchain.apis()
    return
    {
        values =
        {
            "toolchain.set_kind"
        ,   "toolchain.set_bindir"
        ,   "toolchain.set_sdkdir"
        ,   "toolchain.set_archs"
        ,   "toolchain.set_homepage"
        ,   "toolchain.set_description"
        }
    ,   keyvalues =
        {
            -- toolchain.set_xxx
            "toolchain.set_formats"
        ,   "toolchain.set_toolset"
        ,   "toolchain.add_toolset"
            -- toolchain.add_xxx
        ,   "toolchain.add_runenvs"
        }
    ,   script =
        {
            -- toolchain.on_xxx
            "toolchain.on_load"
        ,   "toolchain.on_check"
        }
    }
end

-- get toolchain directories
function toolchain.directories()
    local dirs = toolchain._DIRS or {   path.join(global.directory(), "toolchains")
                                    ,   path.join(os.programdir(), "toolchains")
                                    }
    toolchain._DIRS = dirs
    return dirs
end

-- load the given toolchain
function toolchain.load(name, opt)

    -- init cache key
    opt = opt or {}
    local plat = opt.plat or config.get("plat") or os.host()
    local arch = opt.arch or config.get("arch") or os.arch()
    local cachekey = name .. plat .. arch

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

    -- save instance to the cache
    local instance = _instance.new(name, result, plat, arch)
    toolchain._TOOLCHAINS[cachekey] = instance
    return instance
end

-- new toolchain
function toolchain.new(name, info, opt)
    opt = opt or {}
    local plat = opt.plat or config.get("plat") or os.host()
    local arch = opt.arch or config.get("arch") or os.arch()
    return _instance.new(name, info, plat, arch)
end

-- return module
return toolchain
