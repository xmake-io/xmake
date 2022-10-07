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
-- See the License for the specific tool governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        tool.lua
--

-- define module
local tool      = tool or {}
local _instance = _instance or {}

-- load modules
local os            = require("base/os")
local path          = require("base/path")
local utils         = require("base/utils")
local table         = require("base/table")
local string        = require("base/string")
local config        = require("project/config")
local sandbox       = require("sandbox/sandbox")
local toolchain     = require("tool/toolchain")
local platform      = require("platform/platform")
local import        = require("sandbox/modules/import")

-- new an instance
function _instance.new(kind, name, program, plat, arch, toolchain_inst)

    -- import "core.tools.xxx"
    local toolclass = nil
    if os.isfile(path.join(os.programdir(), "modules", "core", "tools", name .. ".lua")) then
        toolclass = import("core.tools." .. name, {nocache = true}) -- @note we need create a tool instance with unique toolclass context (_g)
    end

    -- not found?
    if not toolclass then
        return nil, string.format("cannot import \"core.tool.%s\" module!", name)
    end

    -- new an instance
    local instance = table.inherit(_instance, toolclass)

    -- save name, kind and program
    instance._NAME      = name
    instance._KIND      = kind
    instance._PROGRAM   = program
    instance._PLAT      = plat
    instance._ARCH      = arch
    instance._TOOLCHAIN = toolchain_inst
    instance._INFO      = {}

    -- init instance
    if instance.init then
        local ok, errors = sandbox.load(instance.init, instance)
        if not ok then
            return nil, errors
        end
    end

    -- ok
    return instance
end

-- get the tool name
function _instance:name()
    return self._NAME
end

-- get the tool kind
function _instance:kind()
    return self._KIND
end

-- get the tool platform
function _instance:plat()
    return self._PLAT
end

-- get the tool architecture
function _instance:arch()
    return self._ARCH
end

-- the current target is belong to the given platforms?
function _instance:is_plat(...)
    local plat = self:plat()
    for _, v in ipairs(table.join(...)) do
        if v and plat == v then
            return true
        end
    end
end

-- the current target is belong to the given architectures?
function _instance:is_arch(...)
    local arch = self:arch()
    for _, v in ipairs(table.join(...)) do
        if v and arch:find("^" .. v:gsub("%-", "%%-") .. "$") then
            return true
        end
    end
end

-- get the tool program
function _instance:program()
    return self._PROGRAM
end

-- get the toolchain of this tool
function _instance:toolchain()
    return self._TOOLCHAIN
end

-- get run environments
function _instance:runenvs()
    return self:toolchain() and self:toolchain():runenvs()
end

-- set the value to the platform info
function _instance:set(name, ...)
    self._INFO[name] = table.unwrap({...})
end

-- add the value to the platform info
function _instance:add(name, ...)
    local info = table.wrap(self._INFO[name])
    self._INFO[name] = table.unwrap(table.join(info, ...))
end

-- get the platform configure
function _instance:get(name)
    if self._super_get then
        local value = self:_super_get(name)
        if value ~= nil then
            return value
        end
    end
    return self._INFO[name]
end

-- has the given flag?
function _instance:has_flags(flags, flagkind, opt)

    -- init options
    opt = opt or {}
    opt.program = opt.program or self:program()
    opt.toolkind = opt.toolkind or self:kind()
    opt.flagkind = opt.flagkind or flagkind

    -- get system flags
    opt.sysflags = opt.sysflags or self:get(self:kind() .. 'flags')
    if not opt.sysflags and opt.flagkind then
        opt.sysflags = self:get(opt.flagkind)
    end

    -- import has_flags()
    self._has_flags = self._has_flags or import("lib.detect.has_flags", {anonymous = true})

    -- bind the run environments
    opt.envs = self:runenvs()

    -- has flags?
    return self._has_flags(self:name(), flags, opt)
end

-- load the given tool from the given kind
--
-- @param kind                the tool kind e.g. cc, cxx, mm, mxx, as, ar, ld, sh, ..
-- @param opt.program         the tool program, e.g. /xxx/arm-linux-gcc, gcc@mipscc.exe, (optional)
-- @param opt.toolname        gcc, clang, .. (optional)
-- @param opt.toolchain_info  the toolchain info (optional)
--
function tool.load(kind, opt)

    -- get tool information
    opt = opt or {}
    local program = opt.program
    local toolname = opt.toolname
    local toolchain_info = opt.toolchain_info or {}

    -- get platform and architecture
    local plat = toolchain_info.plat or config.get("plat") or os.host()
    local arch = toolchain_info.arch or config.get("arch") or os.arch()

    -- init cachekey
    local cachekey = kind .. (program or "") .. plat .. arch

    -- get it directly from cache dirst
    tool._TOOLS = tool._TOOLS or {}
    if tool._TOOLS[cachekey] then
        return tool._TOOLS[cachekey]
    end

    -- contain toolname? parse it, e.g. 'gcc@xxxx.exe'
    if program then
        local pos = program:find('@', 1, true)
        if pos then
            -- we need ignore valid path with `@`, e.g. /usr/local/opt/go@1.17/bin/go
            -- https://github.com/xmake-io/xmake/issues/2853
            local prefix = program:sub(1, pos - 1)
            if prefix and not prefix:find("[/\\]") then
                toolname = prefix
                program = program:sub(pos + 1)
            end
        end
    end

    -- get the tool program and name
    if not program then
        program, toolname, toolchain_info = platform.tool(kind, plat, arch)
        if toolchain_info then
            assert(toolchain_info.plat == plat)
            assert(toolchain_info.arch == arch)
        end
    end
    if not program then
        return nil, string.format("cannot get program for %s", kind)
    end

    -- import find_toolname()
    tool._find_toolname = tool._find_toolname or import("lib.detect.find_toolname")

    -- get the tool name from the program
    local ok, name_or_errors = sandbox.load(tool._find_toolname, toolname or program, {program = program})
    if not ok then
        return nil, name_or_errors
    end

    -- get name
    local name = name_or_errors
    if not name then
        return nil, string.format("cannot find known tool script for %s", toolname or program)
    end

    -- load toolchain instance
    local toolchain_inst
    if toolchain_info and toolchain_info.name then
        toolchain_inst = toolchain.load(toolchain_info.name, {plat = plat, arch = arch, cachekey = toolchain_info.cachekey})
    end

    -- new an instance
    local instance, errors = _instance.new(kind, name, program, plat, arch, toolchain_inst)
    if not instance then
        return nil, errors
    end
    tool._TOOLS[cachekey] = instance
    return instance
end

-- return module
return tool
