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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.package.repository")

-- add repository url
function _add(name, url, global)

    -- get previous url
    local prevurl = repository.get(name, global)
    if not prevurl then

        -- add it
        repository.add(name, url, global)

        -- trace
        cprint("${bright}add repository(%s): %s ok!", name, url)
    else
        -- error
        raise("repository(%s): already exists, please run `xmake repo set` to override it!", name)
    end
end

-- set repository url
function _set(name, url, global)

    -- set it
    repository.set(name, url, global)

    -- trace
    cprint("${bright}set repository(%s): %s ok!", name, url)
end

-- remove repository url
function _remove(name, global)

    -- get url
    local url = repository.get(name, global)
    if url then

        -- remove it
        repository.remove(name, global)

        -- trace
        cprint("${bright}remove repository(%s): %s ok!", name, url)
    else
        -- error
        raise("repository(%s): not found!", name)
    end
end

-- list all repositories
function _list(name, global)
end

-- main
function main()

    -- add repository url 
    if option.get("add") then

        _add(option.get("name"), option.get("url"), option.get("global"))

    -- set repository url
    elseif option.get("set") then

        _set(option.get("name"), option.get("url"), option.get("global"))

    -- remove repository url
    elseif option.get("remove") then

        _remove(option.get("name"), option.get("global"))

    -- list all repositories
    elseif option.get("list") then

        _list(option.get("global"))

    -- show help
    else
        option.show_help()
    end
end

