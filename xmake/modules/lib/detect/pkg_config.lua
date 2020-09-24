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
-- @file        pkg_config.lua
--

-- imports
import("core.base.global")
import("core.project.target")
import("core.project.config")
import("lib.detect.find_file")
import("lib.detect.find_library")
import("detect.tools.find_pkg_config")

-- get version
--
-- @param name      the package name
-- @param opt       the argument options, {configdirs = {"/xxxx/pkgconfig/"}}
--
function version(name, opt)

    -- attempt to add search paths from pkg-config
    local pkg_config = find_pkg_config()
    if not pkg_config then
        return
    end

    -- init options
    opt = opt or {}

    -- init PKG_CONFIG_PATH
    local configdirs_old = os.getenv("PKG_CONFIG_PATH")
    local configdirs = table.wrap(opt.configdirs)
    if #configdirs > 0 then
        os.setenv("PKG_CONFIG_PATH", unpack(configdirs))
    end

    -- get version
    local version = try { function() return os.iorunv(pkg_config, {"--modversion", name}) end }
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
    local pkg_config = find_pkg_config()
    if not pkg_config then
        return
    end

    -- init options
    opt = opt or {}

    -- init PKG_CONFIG_PATH
    local configdirs_old = os.getenv("PKG_CONFIG_PATH")
    local configdirs = table.wrap(opt.configdirs)
    if #configdirs > 0 then
        os.setenv("PKG_CONFIG_PATH", unpack(configdirs))
    end

    -- get variable value
    local result = nil
    if variables then
        for _, variable in ipairs(table.wrap(variables)) do
            local value = try { function () return os.iorunv(pkg_config, {"--variable=" .. variable, name}) end }
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
-- local libinfo = pkg_config.libinfo("openssl")
--
-- @endcode
--
function libinfo(name, opt)

    -- attempt to add search paths from pkg-config
    local pkg_config = find_pkg_config()
    if not pkg_config then
        return
    end

    -- init options
    opt = opt or {}

    -- init PKG_CONFIG_PATH
    local configdirs_old = os.getenv("PKG_CONFIG_PATH")
    local configdirs = table.wrap(opt.configdirs)
    if #configdirs > 0 then
        os.setenv("PKG_CONFIG_PATH", unpack(configdirs))
    end

    -- get libs and cflags
    local result = nil
    local flags = try { function () return os.iorunv(pkg_config, {"--libs", "--cflags", name}) end }
    if flags then

        -- init result
        result = {}
        for _, flag in ipairs(os.argv(flags)) do
            if flag:startswith("-L") and #flag > 2 then
                -- get linkdirs
                local linkdir = flag:sub(3)
                if linkdir and os.isdir(linkdir) then
                    result.linkdirs = result.linkdirs or {}
                    table.insert(result.linkdirs, linkdir)
                end
            elseif flag:startswith("-I") and #flag > 2 then
                -- get includedirs
                local includedir = flag:sub(3)
                if includedir and os.isdir(includedir) then
                    result.includedirs = result.includedirs or {}
                    table.insert(result.includedirs, includedir)
                end
            elseif flag:startswith("-l") and #flag > 2 then
                -- get links
                local link = flag:sub(3)
                result.links = result.links or {}
                table.insert(result.links, link)
            end
        end
    end

    -- get version
    local version = try { function() return os.iorunv(pkg_config, {"--modversion", name}) end }
    if version then
        result = result or {}
        result.version = version:trim()
    end

    -- restore PKG_CONFIG_PATH
    if configdirs_old then
        os.setenv("PKG_CONFIG_PATH", configdirs_old)
    end
    return result
end

