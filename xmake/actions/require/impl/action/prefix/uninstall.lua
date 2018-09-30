--!The Make-like install Utility based on Lua
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
-- @file        uninstall.lua
--

-- uninstall package from the prefix directory
function main(package)

    -- remove the previous installed files
    local prefixdir = package:prefixdir()
    for _, relativefile in ipairs(package:prefixinfo().installed) do

        -- trace
        vprint("removing %s ..", relativefile)

        -- remove file
        local prefixfile = path.absolute(relativefile, prefixdir)
        os.tryrm(prefixfile)
 
        -- remove it if the parent directory is empty
        local parentdir = path.directory(prefixfile)
        while parentdir and os.isdir(parentdir) and os.emptydir(parentdir) do
            os.tryrm(parentdir)
            parentdir = path.directory(parentdir)
        end
    end

    -- unregister this package
    package:unregister()

    -- remove the prefix file
    os.tryrm(package:prefixfile())
end

