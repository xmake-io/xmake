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
-- @file        find_vstudio.lua
--

-- imports
import("lib.detect.find_file")

-- find vstudio environment
--
-- @return      { 2008 = {version = "9.0", vcvarsall = "C:\Program Files\Microsoft Visual Studio 9.0\VC\vcvarsall.bat"}
--              , 2017 = {version = "15.0", vcvarsall = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat"}}
--
function main()

    -- init vsvers
    local vsvers = 
    {
        ["15.0"] = "2017"
    ,   ["14.0"] = "2015"
    ,   ["12.0"] = "2013"
    ,   ["11.0"] = "2012"
    ,   ["10.0"] = "2010"
    ,   ["9.0"]  = "2008"
    ,   ["8.0"]  = "2005"
    ,   ["7.1"]  = "2003"
    ,   ["7.0"]  = "7.0"
    ,   ["6.0"]  = "6.0"
    ,   ["5.0"]  = "5.0"
    ,   ["4.2"]  = "4.2"
    }

    -- find vs2017 -> vs4.2
    local results = {}
    for _, version in ipairs({"15.0", "14.0", "12.0", "11.0", "10.0", "9.0", "8.0", "7.1", "7.0", "6.0", "5.0", "4.2"}) do

        -- find vcvarsall.bat
        local vcvarsall = find_file("vcvarsall.bat", {format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\VC", version),
                                                      format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\VC", version),
                                                      format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\VC\\Auxiliary\\Build", version),
                                                      format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\VC\\Auxiliary\\Build", version)})

        -- found?
        if vcvarsall then
            results[vsvers[version]] = {version = version, vcvarsall = vcvarsall}
        end
    end

    -- ok?
    return results
end
