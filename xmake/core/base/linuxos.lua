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
-- @file        linuxos.lua
--

-- define module: linuxos
local linuxos = linuxos or {}

-- load modules
local os     = require("base/os")
local path   = require("base/path")
local semver = require("base/semver")

-- get lsb_release information
--
-- e.g.
--
-- Distributor ID:	Ubuntu
-- Description:	Ubuntu 16.04.7 LTS
-- Release:	16.04
-- Codename:	xenial
--
function linuxos._lsb_release()
    local lsb_release = linuxos._LSB_RELEASE
    if lsb_release == nil then
        local ok, result = os.iorun("lsb_release -a")
        if ok then
            lsb_release = result
        end
        if lsb_release then
            lsb_release = lsb_release:trim():lower()
        end
        linuxos._LSB_RELEASE = lsb_release or false
    end
    return lsb_release or nil
end

-- get uname information
function linuxos._uname_r()
    local uname_r = linuxos._UNAME_R
    if uname_r == nil then
        local ok, result = os.iorun("uname -r")
        if ok then
            uname_r = result
        end
        if uname_r then
            uname_r = uname_r:trim():lower()
        end
        linuxos._UNAME_R = uname_r or false
    end
    return uname_r or nil
end

-- get system name
--
-- e.g.
--  - ubuntu
--  - debian
--  - archlinux
--  - rhel
--  - centos
--  - fedora
--  - opensuse
--  - ...
function linuxos.name()
    local name = linuxos._NAME
    if name == nil then
        -- get it from /etc/os-release first
        if name == nil and os.isfile("/etc/os-release") then
            local os_release = io.readfile("/etc/os-release")
            if os_release then
                os_release = os_release:trim():lower()
                if os_release:find("arch linux", 1, true) or os_release:find("archlinux", 1, true) then
                    name = "archlinux"
                elseif os_release:find("centos linux", 1, true) or os_release:find("centos", 1, true) then
                    name = "centos"
                elseif os_release:find("fedora", 1, true) then
                    name = "fedora"
                elseif os_release:find("linux mint", 1, true) or os_release:find("linuxmint", 1, true) then
                    name = "linuxmint"
                elseif os_release:find("ubuntu", 1, true) then
                    name = "ubuntu"
                elseif os_release:find("debian", 1, true) then
                    name = "debian"
                elseif os_release:find("opensuse", 1, true) then
                    name = "opensuse"
                elseif os_release:find("manjaro", 1, true) then
                    name = "manjaro"
                end
            end
        end

        -- get it from lsb release
        if name == nil then
            local lsb_release = linuxos._lsb_release()
            if lsb_release and lsb_release:find("ubuntu", 1, true) then
                name = "ubuntu"
            end
        end

        -- is archlinux?
        if name == nil and os.isfile("/etc/arch-release") then
            name = "archlinux"
        end

        -- unknown
        name = name or "unknown"
        linuxos._NAME = name
    end
    return name
end

-- get system version
function linuxos.version()
    local version = linuxos._VERSION
    if version == nil then

        -- get it from /etc/os-release first
        if version == nil and os.isfile("/etc/os-release") then
            local os_release = io.readfile("/etc/os-release")
            if os_release then
                os_release = os_release:trim():lower():split("\n")
                for _, line in ipairs(os_release) do
                    -- ubuntu: VERSION="16.04.7 LTS (Xenial Xerus)"
                    -- fedora: VERSION="32 (Container Image)"
                    -- debian: VERSION="9 (stretch)"
                    if line:find("version=") then
                        line = line:sub(9)
                        version = semver.match(line)
                        if not version then
                            version = line:match("\"(%d+)%s+.*\"")
                            if version then
                                version = semver.new(version .. ".0")
                            end
                        end
                        if version then
                            break
                        end
                    end
                end
            end
        end

        -- get it from lsb release
        if version == nil then
            local lsb_release = linuxos._lsb_release()
            if lsb_release and lsb_release:find("ubuntu", 1, true) then
                for _, line in ipairs(lsb_release:split("\n")) do
                    -- release:	16.04
                    if line:find("release:") then
                        version = semver.match(line, 9)
                        if version then
                            break
                        end
                    end
                end
            end
        end
        linuxos._VERSION = version
    end
    return version
end

-- get linux kernel version
function linuxos.kernelver()
    local version = linuxos._KERNELVER
    if version == nil then
        if version == nil then
            local uname_r = linuxos._uname_r()
            if uname_r then
                version = semver.match(uname_r)
            end
        end
        linuxos._KERNELVER = version
    end
    return version
end

-- return module: linuxos
return linuxos
