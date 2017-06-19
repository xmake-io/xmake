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
-- @file        find_zlib.lua
--

-- imports
import("lib.detect.find_path")
import("lib.detect.find_library")

-- find zlib 
--
-- @param opt   the package options. e.g. see the options of find_package()
--
-- @return      see the return value of find_package()
--
function main(opt)

    -- for windows platform
    --
    -- http://gnuwin32.sourceforge.net/packages/zlib.html
    --
    if opt.plat == "windows" then

        -- init search pathes
        local pathes = {"$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\GnuWin32\\Zlib;InstallPath)",
                        "$(env PROGRAMFILES)/GnuWin32",
                        "$(env PROGRAMFILES)/zlib"}

        -- find library
        local result = {links = {}, linkdirs = {}, includedirs = {}}
        local linkinfo = find_library("zlib", pathes, {suffixes = "lib"})
        if not linkinfo then
            return 
        end

        -- save link and directory
        table.insert(result.links, linkinfo.link)
        table.insert(result.linkdirs, linkinfo.linkdir)

        -- find include
        local includedir = find_path("zlib.h", pathes, {suffixes = "include"})
        if includedir then

            -- save include directory
            table.insert(result.includedirs, includedir)

            -- match version
            if opt.version then
                local zlib_h = io.readfile(path.join(includedir, "zlib.h"))
                if zlib_h then
                    local version = zlib_h:match("#define ZLIB_VERSION \"(%d+%.?%d+%.?%d+)\"")
                    if version ~= opt.version then
                        return 
                    end
                end
            end
        end

        -- ok
        return result
    end
end
