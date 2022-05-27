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
-- @file        pkgconfig.lua
--

-- imports
import("core.base.global")
import("core.project.target")
import("core.project.config")
import("lib.detect.find_file")
import("lib.detect.find_library")
import("lib.detect.find_tool")

-- get pkgconfig
function _get_pkgconfig()
    local pkgconfig = find_tool("pkg-config") or find_tool("pkgconf")
    if pkgconfig then
        return pkgconfig.program
    end
end

-- get version
--
-- @param name      the package name
-- @param opt       the argument options, {configdirs = {"/xxxx/pkgconfig/"}}
--
function version(name, opt)

    -- attempt to add search paths from pkg-config
    local pkgconfig = _get_pkgconfig()
    if not pkgconfig then
        return
    end

    -- init options
    opt = opt or {}

    -- init PKG_CONFIG_PATH
    local configdirs_old = os.getenv("PKG_CONFIG_PATH")
    local configdirs = table.wrap(opt.configdirs)
    if #configdirs > 0 then
        os.setenv("PKG_CONFIG_PATH", table.unpack(configdirs))
    end

    -- get version
    local version = try { function() return os.iorunv(pkgconfig, {"--modversion", name}) end }
    if version then
        version = version:trim()
    end

    -- restore PKG_CONFIG_PATH
    if configdirs_old then
        os.setenv("PKG_CONFIG_PATH", configdirs_old)
    end

    -- ok?
    return version
end

-- get variables
--
-- @param name      the package name
-- @param variables the variables
-- @param opt       the argument options, {configdirs = {"/xxxx/pkgconfig/"}}
--
function variables(name, variables, opt)

    -- attempt to add search paths from pkg-config
    local pkgconfig = _get_pkgconfig()
    if not pkgconfig then
        return
    end

    -- init options
    opt = opt or {}

    -- init PKG_CONFIG_PATH
    local configdirs_old = os.getenv("PKG_CONFIG_PATH")
    local configdirs = table.wrap(opt.configdirs)
    if #configdirs > 0 then
        os.setenv("PKG_CONFIG_PATH", table.unpack(configdirs))
    end

    -- get variable value
    local result = nil
    if variables then
        for _, variable in ipairs(table.wrap(variables)) do
            local value = try { function () return os.iorunv(pkgconfig, {"--variable=" .. variable, name}) end }
            if value ~= nil then
                result = result or {}
                result[variable] = value:trim()
            end
        end
    end

    -- restore PKG_CONFIG_PATH
    if configdirs_old then
        os.setenv("PKG_CONFIG_PATH", configdirs_old)
    end

    -- ok?
    return result
end

-- get library info
--
-- @param name  the package name
-- @param opt   the argument options, {version = true, variables = "includedir", configdirs = {"/xxxx/pkgconfig/"}}
--
-- @return      {links = {"ssl", "crypto", "z"}, linkdirs = {""}, includedirs = {""}, version = ""}
--
-- @code
--
-- local libinfo = pkgconfig.libinfo("openssl")
--
-- @endcode
--
function libinfo(name, opt)

    -- attempt to add search paths from pkg-config
    local pkgconfig = _get_pkgconfig()
    if not pkgconfig then
        return
    end

    -- init options
    opt = opt or {}

    -- init PKG_CONFIG_PATH
    local envs = {}
    local configdirs = table.wrap(opt.configdirs)
    if #configdirs > 0 then
        envs.PKG_CONFIG_PATH = path.joinenv(configdirs)
    end

    -- get cflags
    local result = nil
    local cflags = try { function () return os.iorunv(pkgconfig, {"--cflags", name}, {envs = envs}) end }
    if cflags then
        result = result or {}
        for _, flag in ipairs(os.argv(cflags)) do
            if flag:startswith("-I") and #flag > 2 then
                local includedir = flag:sub(3)
                if includedir and os.isdir(includedir) then
                    result.includedirs = result.includedirs or {}
                    table.insert(result.includedirs, includedir)
                end
            elseif flag:startswith("-D") and #flag > 2 then
                local define = flag:sub(3)
                result.defines = result.defines or {}
                table.insert(result.defines, define)
            elseif flag:startswith("-") and #flag > 1 then
                result.cxflags = result.cxflags or {}
                table.insert(result.cxflags, flag)
            end
        end
    end

    -- get libs and ldflags
    local ldflags = try { function () return os.iorunv(pkgconfig, {"--libs", name}, {envs = envs}) end }
    if ldflags then
        result = result or {}
        for _, flag in ipairs(os.argv(ldflags)) do
            if flag:startswith("-L") and #flag > 2 then
                local linkdir = flag:sub(3)
                if linkdir and os.isdir(linkdir) then
                    result.linkdirs = result.linkdirs or {}
                    table.insert(result.linkdirs, linkdir)
                end
            elseif flag:startswith("-l") and #flag > 2 then
                local link = flag:sub(3)
                result.links = result.links or {}
                table.insert(result.links, link)
            elseif flag:startswith("-") and #flag > 1 then
                result.ldflags = result.ldflags or {}
                result.shflags = result.shflags or {}
                table.insert(result.ldflags, flag)
                table.insert(result.shflags, flag)
            end
        end
    end


    -- get version
    local version = try { function() return os.iorunv(pkgconfig, {"--modversion", name}, {envs = envs}) end }
    if version then
        result = result or {}
        result.version = version:trim()
    end
    return result
end

