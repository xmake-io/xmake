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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        clean.lua
--

-- imports
import("core.base.option")
import("core.project.cache")
import("core.package.package")

-- clean all installed package caches
function main()

    -- trace
    print("clear all package caches ..")

    -- clear cache directory
    os.rm(package.cachedir())

    -- clear require cache
    local require_cache = cache("local.require")
    require_cache:clear()
    require_cache:flush()

    -- trace
    print("clear all unused packages ..")

    -- clear all unused packages
    local installdir = package.installdir()
    for _, references_file in ipairs(os.files(path.join(installdir, "*", "*", "*", "*", "references.txt"))) do
        local references = io.load(references_file)
        if references then
            local found = false
            for projectdir, refdate in pairs(references) do
                if os.isdir(projectdir) then
                    found = true
                    break
                end
            end
            if not found then

                -- get package directory
                local packagedir = path.directory(references_file)
                print("remove %s ..", packagedir)

                -- get confirm
                local confirm = option.get("yes")
                if confirm == nil then

                    -- show tips
                    cprint("${bright color.warning}note: ${clear}no projects are using this package, remove it (pass -y to skip confirm)?")
                    cprint("please input: y (y/n)")

                    -- get answer
                    io.flush()
                    local answer = io.read()
                    if answer == 'y' or answer == '' then
                        confirm = true
                    end
                end
                if confirm then
                    os.rm(packagedir)
                end
            end
        end
    end
end

