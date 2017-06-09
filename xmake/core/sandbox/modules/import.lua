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
-- @file        import.lua
--

-- define module
local sandbox_import = sandbox_import or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local table     = require("base/table")
local string    = require("base/string")
local global    = require("project/global")
local sandbox   = require("sandbox/sandbox")
local raise     = require("sandbox/modules/raise")

-- get module name
function sandbox_import._modulename(name)

    -- check
    assert(name)

    -- find modulename
    local i = name:find_last(".", true)
    if i then
        name = name:sub(i + 1)
    end

    -- get it
    return name
end

-- get module path from name
function sandbox_import._modulepath(name)

    -- translate module path
    --
    -- "package.module" => "package/module"
    -- "..package.module" => "../../package/module"
    --
    local startdots = true
    local modulepath = name:gsub(".", function(c)
        if c == '.' then
            if startdots then
                return ".." .. path.seperator()
            else
                return path.seperator()
            end
        else
            startdots = false
            return c
        end
    end)

    -- return module path
    return modulepath
end

-- load module from file
function sandbox_import._loadfile(filepath, instance)

    -- check
    assert(filepath)

    -- load module script
    local script, errors = loadfile(filepath)
    if not script then
        return nil, errors
    end

    -- with sandbox?
    if instance then

        -- fork a new sandbox for this script
        instance, errors = instance:fork(script, path.directory(filepath))
        if not instance then
            return nil, errors
        end

        -- import module
        local result, errors = instance:import()
        if not result then
            return nil, errors
        end
        
        -- ok
        return result, instance:script()
    end

    -- load module without sandbox
    local ok, result = xpcall(script, debug.traceback)
    if not ok then
        return nil, result
    end

    -- ok?
    return result, script
end

-- find module
function sandbox_import._find(dir, name)

    -- check
    assert(dir and name)

    -- get module path
    name = sandbox_import._modulepath(name)
    assert(name)

    -- load the single module?
    local module = nil
    if os.isfile(path.join(dir, name .. ".lua")) then
        return true

    -- load modules
    elseif os.isdir(path.join(dir, name)) then
        return true
    end

    -- not found
    return false

end

-- load module
function sandbox_import._load(dir, name, instance)

    -- check
    assert(dir and name)

    -- get module path
    name = sandbox_import._modulepath(name)
    assert(name)

    -- load the single module?
    local module = nil
    local script = nil
    if os.isfile(path.join(dir, name .. ".lua")) then

        -- load module
        local result, errors = sandbox_import._loadfile(path.join(dir, name .. ".lua"), instance)
        if not result then
            return nil, errors
        end

        -- save module
        module = result

        -- save script
        script = errors

    -- load modules
    elseif os.isdir(path.join(dir, name)) then

        -- get modulefiles
        local moduleroot = path.join(path.join(dir, name))
        local modulefiles = os.match(path.join(moduleroot, "**.lua"))
        if modulefiles then
            for _, modulefile in ipairs(modulefiles) do

                -- load module
                local result, errors = sandbox_import._loadfile(modulefile, instance)
                if not result then
                    return nil, errors
                end

                -- bind main entry 
                if result.main then
                    setmetatable(result, { __call = function (_, ...) return result.main(...) end})
                end

                -- get the module path
                local modulepath = path.relative(modulefile, moduleroot)
                if not modulepath then
                    return nil, string.format("cannot get the path for module: %s", name)
                end

                -- init the root module
                module = module or {}

                -- save script
                script = errors

                -- save module
                local scope = module
                for _, modulename in ipairs(path.split(modulepath)) do
                    
                    -- is end?
                    local pos = modulename:find(".lua", 1, true)
                    if pos then

                        -- get the module name
                        modulename = modulename:sub(1, pos - 1)
                        assert(modulename)

                        -- save module
                        scope[modulename] = result

                    -- is scope?
                    else
 
                        -- enter submodule
                        scope[modulename] = scope[modulename] or {}
                        scope = scope[modulename]
                    end
                end
            end
        end
    end
    
    -- this module not found?
    if not module then
        return nil, string.format("module: %s not found!", name)
    end

    -- return it
    return module, script
end

-- import module
--
-- .e.g 
--
-- import("core.platform")
-- => platform
-- 
-- import("core.platform", {alias = "p"})
-- => p
--
-- import("core")
-- => core
-- => core.platform
---
-- import("core", {rootdir = "/scripts"})
-- => core
-- => core.platform
--
-- import("core.platform", {inherit = true})
-- => inherit the all interfaces of core.platform to the current scope
--
-- local test = import("test", {rootdir = "/tmp/xxx", anonymous = true})
-- => only return imported module and do not cache it
--
-- @note the polymiorphism is not supported for import.inherit mode now.
--
function sandbox_import.import(name, args)

    -- check
    assert(name)

    -- the arguments
    args = args or {}

    -- get the parent scope
    local scope_parent = getfenv(2)
    assert(scope_parent)

    -- get module name
    local modulename = sandbox_import._modulename(name)
    if not modulename then
        raise("cannot get module name for %s", name)
    end

    -- the imported name
    local imported_name = args.alias or modulename

    -- this module has been imported?
    local module = rawget(scope_parent, imported_name)
    if module ~= nil then
        return module
    end

    -- get the current sandbox instance
    local instance = sandbox.instance()
    assert(instance)

    -- the root directory for this sandbox script
    local rootdir = args.rootdir or instance:rootdir()
    assert(rootdir)

    -- the sandbox modules directory
    local modules_sandbox_dir = path.join(xmake._CORE_DIR, "sandbox/modules/import")

    -- the extension modules directory
    local modules_extension_dir = path.join(os.programdir(), "modules")

    -- the global modules directory for users
    local modules_global_dir = path.join(global.directory(), "modules")

    -- init module directories
    local modules_directories = 
    {
        rootdir                                                 -- load module from the given root directory first 
    ,   path.join(global.directory(), "modules")                -- load module from the user global modules directory
    ,   path.join(xmake._PROGRAM_DIR, "modules")                -- load module from the extension modules directory
    ,   path.join(xmake._CORE_DIR, "sandbox/modules/import")    -- load module from the sandbox core modules directory
    }

    -- load module
    local module = nil
    local errors = nil
    for idx, moduledir in ipairs(modules_directories) do
        if sandbox_import._find(moduledir, name) then
            module, errors = sandbox_import._load(moduledir, name, utils.ifelse(idx < #modules_directories, instance, nil)) -- last modules need not fork sandbox
        end
    end

    -- check
    if not module then
        raise("cannot import module: %s, %s", name, errors)
    end

    -- get module script
    local script = errors

    -- inherit?
    if args.inherit then
 
        -- inherit this module into the parent scope
        table.inherit2(scope_parent, module)

        -- import as super module
        imported_name = "_super"

        -- public the script scope for the super module
        --
        -- we can access the all scope members of _super in the child module
        --
        -- .e.g
        --
        -- import("core.platform.xxx", {inherit = true})
        --
        -- print(_super._g)
        -- 
        if script ~= nil then
            setmetatable(module, {  __index = function (tbl, key)
                                        local val = rawget(tbl, key)
                                        if val == nil then
                                            val = rawget(getfenv(script), key)
                                        end
                                        return val
                                    end})

        end

    end

    -- bind main entry 
    if module.main then
        setmetatable(module, { __call = function (_, ...) return module.main(...) end})
    end

    -- import this module into the parent scope
    if not args.anonymous then
        scope_parent[imported_name] = module
    end

    -- return it
    return module
end

-- load module
return sandbox_import.import

