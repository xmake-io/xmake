--!The Automatic Cross-platform Build Tool
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
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
local sandbox   = require("sandbox/sandbox")

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
        instance, errors = instance:fork(script)
        if not instance then
            return nil, errors
        end

        -- backup the scope variables first
        local scope_public = getfenv(instance:script())
        local scope_backup = {}
        table.copy2(scope_backup, scope_public)

        -- load module with sandbox
        local ok, errors = sandbox.load(instance:script())
        if not ok then
            return nil, errors
        end

        -- only export new public functions
        local result = {}
        for k, v in pairs(scope_public) do
            if type(v) == "function" and scope_backup[k] == nil then
                result[k] = v
            end
        end

        -- get module
        return result
    end

    -- load module without sandbox
    local ok, result = xpcall(script, debug.traceback)
    if not ok then
        return nil, result
    end

    -- ok?
    return result
end

-- load module
function sandbox_import._load(dir, name, instance)

    -- check
    assert(dir and name)

    -- replace "package.module" => "package/module"
    name = (name:gsub("%.", "/"))
    assert(name)

    -- load the single module?
    local module = nil
    if os.isfile(path.join(dir, name .. ".lua")) then

        -- load module
        local result, errors = sandbox_import._loadfile(path.join(dir, name .. ".lua"), instance)
        if not result then
            return nil, errors
        end

        -- save module
        module = result

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

                -- get the module path
                local modulepath = path.relative(modulefile, moduleroot)
                if not modulepath then
                    return nil, string.format("cannot get the path for module: %s", name)
                end

                -- init the root module
                module = module or {}

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
    return module
end

-- import module
--
-- .e.g 
--
-- import("core.platform")
-- => platform
-- 
-- import("core.platform", "p")
-- => p
--
-- import("core")
-- => core
-- => core.platform
--
function sandbox_import.import(name, alias)

    -- check
    assert(name)

    -- get the current sandbox instance
    local instance = sandbox.instance()
    assert(instance)

    -- the root directory for this sandbox script
    local rootdir = instance:rootdir()
    assert(rootdir)

    -- load module from the sandbox root directory first
    local module, errors = sandbox_import._load(rootdir, name, instance)
    if not module then
        -- load module from the sandbox core directory
        module, errors = sandbox_import._load(path.join(xmake._CORE_DIR, "sandbox/modules/import"), name)
    end

    -- check
    if not module then
        os.raise("cannot import module: %s, %s", name, errors)
    end

    -- get module name
    local modulename = sandbox_import._modulename(name)
    if not modulename then
        os.raise("cannot get module name for %s", name)
    end

    -- get the parent scope
    local scope_parent = getfenv(2)
    assert(scope_parent)

    -- this module has been imported?
    if rawget(scope_parent, modulename) then
        os.raise("this module: %s has been imported!", name)
    end

    -- import this module into the parent scope
    scope_parent[alias or modulename] = module

    -- return it
    return module
end

-- load module
return sandbox_import.import

