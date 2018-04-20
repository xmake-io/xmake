--!A cross-platform build utility based on Lua
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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        load.lua
--

-- the main entry
function main(target, opt)

    -- init options
    opt = opt or {}

    -- check qt sdk
    local qt = target:data("qt")

    -- set kind
    if opt.kind then
        target:set("kind", opt.kind)
    end

    -- need c++11
    target:set("languages", "cxx11")

    -- add defines for the compile mode
    if is_mode("debug") then
        target:add("defines", "QT_QML_DEBUG")
    elseif is_mode("release") then
        target:add("defines", "QT_NO_DEBUG")
    elseif is_mode("profile") then
        target:add("defines", "QT_QML_DEBUG", "QT_NO_DEBUG")
    end

    -- The following define makes your compiler emit warnings if you use
    -- any feature of Qt which as been marked deprecated (the exact warnings
    -- depend on your compiler). Please consult the documentation of the
    -- deprecated API in order to know how to port your code away from it.
    target:add("defines", "QT_DEPRECATED_WARNINGS")

    -- add frameworks
    if opt.frameworks then
        target:add("frameworks", opt.frameworks)
    end

    -- do frameworks for qt
    for _, framework in ipairs(target:get("frameworks")) do

        -- translate qt frameworks
        if framework:startswith("Qt") then

            -- add defines
            target:add("defines", "QT_" .. framework:sub(3):upper() .. "_LIB")
            
            -- add includedirs for macosx
            if is_plat("macosx") then
                target:add("includedirs", path.join(qt.sdkdir, "lib/" .. framework .. ".framework/Headers"))
            end
        end
    end

    -- add includedirs, linkdirs for macosx
    if is_plat("macosx") then
        target:add("frameworkdirs", qt.linkdirs)
        target:add("frameworks", "DiskArbitration", "IOKit")
        target:add("includedirs", path.join(qt.sdkdir, "mkspecs/macx-clang"))
        target:add("rpathdirs", "@executable_path/Frameworks", qt.linkdirs)
    else
        target:set("frameworks", nil)
    end
end

