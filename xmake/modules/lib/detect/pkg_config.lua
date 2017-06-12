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
-- @file        pkg_config.lua
--

-- imports
import("detect.tool.find_pkg_config")

-- find package  
--
-- @param name  the package name
-- @param opt   the argument options, {version = true}
--
-- @return      {links = {"ssl", "crypto", "z"}, linkdirs = {""}, includedirs = {""}, version = ""}
--
-- @code 
--
-- local pkginfo = pkg_config.find("openssl")
-- 
-- @endcode
--
function find(name, opt)
    
    -- attempt to add search pathes from pkg-config
    local pkg_config = find_pkg_config()
    if not pkg_config then
        return 
    end

    -- get libs and cflags
    local result = nil
    local flags = try { function () return os.iorunv(pkg_config, {"--libs", "--cflags", name}) end }
    if flags then

        -- init result
        result = {}
        for _, flag in ipairs(flags:split('%s*')) do

            -- get links
            local link = flag:match("%-l(.*)") 
            if link then
                result.links = result.links or {}
                table.insert(result.links, link)
            end
       
            -- get linkdirs
            local linkdirs = nil
            local linkdir = flag:match("%-L(.*)") 
            if linkdir and os.isdir(linkdir) then
                result.linkdirs = result.linkdirs or {}
                table.insert(result.linkdirs, linkdir)
            end
       
            -- get includedirs
            local includedirs = nil
            local includedir = flag:match("%-I(.*)") 
            if includedir and os.isdir(includedir) then
                result.includedirs = result.includedirs or {}
                table.insert(result.includedirs, includedir)
            end
        end
    end

    -- find version
    if opt and opt.version then

        -- get version
        local version = try { function() return os.iorunv(pkg_config, {"--modversion", name}) end }
        if version then
            result = result or {}
            result.version = version
        end
    end

    -- ok?
    return result
end
