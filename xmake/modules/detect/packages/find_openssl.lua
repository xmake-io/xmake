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
-- @file        find_openssl.lua
--

-- imports
import("lib.detect.find_path")
import("lib.detect.find_library")

-- find openssl
--
-- @param opt   the package options. e.g. see the options of find_package()
--
-- @return      see the return value of find_package()
--
function main(opt)

    -- for windows platform
    --
    -- http://www.slproweb.com/products/Win32OpenSSL.html
    --
    if opt.plat == "windows" then

        -- init bits
        local bits = (opt.arch == "x64" and "64" or "32")

        -- init search paths
        local paths = {"$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\OpenSSL %(" .. bits .. "-bit%)_is1;Inno Setup: App Path)",
                        "$(env PROGRAMFILES)/OpenSSL",
                        "$(env PROGRAMFILES)/OpenSSL-Win" .. bits,
                        "C:/OpenSSL",
                        "C:/OpenSSL-Win" .. bits}

        -- find library
        local result = {links = {}, linkdirs = {}, includedirs = {}}
        for _, name in ipairs({"libssl", "libcrypto"}) do
            local linkinfo = find_library(name, paths, {suffixes = "lib"})
            if linkinfo then
                table.insert(result.links, linkinfo.link)
                table.insert(result.linkdirs, linkinfo.linkdir)
            end
        end

        -- not found?
        if #result.links ~= 2 then
            return
        end

        -- find include
        table.insert(result.includedirs, find_path("openssl/ssl.h", paths, {suffixes = "include"}))

        -- ok
        return result
    end
end
