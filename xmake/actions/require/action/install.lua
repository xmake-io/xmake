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
-- @file        install.lua
--

-- imports
import("build")
import("download")

-- on install the given package
function _on_install_package(package)
end

-- install the given package
function main(package, cachedir)

    -- get working directory of this package
    local workdir = path.join(cachedir, package:name() .. "-" .. (package:version() or "group"))

    -- ensure the working directory first
    os.mkdir(workdir)

    -- enter the working directory
    local oldir = os.cd(workdir)

    -- download package first
    download.main(package)

    -- build package 
    build.main(package)

    -- the package scripts
    local scripts =
    {
        package:get("install_before") 
    ,   package:get("install")  or _on_install_package
    ,   package:get("install_after") 
    }

    -- run the package scripts
    for i = 1, 3 do
        local script = scripts[i]
        if script ~= nil then
            script(package)
        end
    end

    -- leave working directory
    os.cd(oldir)
end

