--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        module.lua
--

-- define module
local core_sandbox_module = core_sandbox_module or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local hash      = require("base/hash")
local utils     = require("base/utils")
local table     = require("base/table")
local string    = require("base/string")
local global    = require("base/global")
local config    = require("project/config")
local memcache  = require("cache/memcache")
local sandbox   = require("sandbox/sandbox")
local raise     = require("sandbox/modules/raise")

-- the module kinds
local MODULE_KIND_LUAFILE = 1
local MODULE_KIND_LUADIR  = 2
local MODULE_KIND_BINARY  = 3
local MODULE_KIND_SHARED  = 4

-- get module path from name
function core_sandbox_module._modulepath(name)

    -- translate module path
    --
    -- "package.module" => "package/module"
    -- "..package.module" => "../../package/module"
    --
    local startdots = true
    local modulepath = name:gsub(".", function(c)
        if c == '.' then
            if startdots then
                return ".." .. path.sep()
            else
                return path.sep()
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
function core_sandbox_module._loadfile(filepath, instance)
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

        -- load module
        local result, errors = instance:module()
        if not result then
            return nil, errors
        end
        return result, instance:script()
    end

    -- load module without sandbox
    local ok, result = utils.trycall(script)
    if not ok then
        return nil, result
    end
    return result, script
end

-- find module
function core_sandbox_module._find(dir, name)
    assert(dir and name)

    -- get module subpath
    local module_subpath = core_sandbox_module._modulepath(name)
    assert(module_subpath)

    -- get module full path
    local module_fullpath = path.join(dir, module_subpath)

    -- single lua module?
    local modulekey = path.normalize(path.absolute(module_fullpath))
    if os.isfile(module_fullpath .. ".lua") then
        return modulekey, MODULE_KIND_LUAFILE
    elseif os.isdir(module_fullpath) then
        local module_projectfile = path.join(module_fullpath, "xmake.lua")
        if os.isfile(module_projectfile) then -- native module? e.g. binary/shared modules
            local content = io.readfile(module_projectfile)
            local kind = content:match("add_rules%(\"module.(.-)\"%)")
            if kind == "binary" then
                return modulekey, MODULE_KIND_BINARY
            elseif kind == "shared" then
                return modulekey, MODULE_KIND_SHARED
            end
        else
            -- module directory
            return modulekey, MODULE_KIND_LUADIR
        end
    end
end

-- load module from the single script file
function core_sandbox_module._load_from_scriptfile(module_fullpath, opt)
    assert(not opt.module)
    return core_sandbox_module._loadfile(module_fullpath .. ".lua", opt.instance)
end

-- load module from the script directory
function core_sandbox_module._load_from_scriptdir(module_fullpath, opt)
    local script
    local module = opt.module
    local modulefiles = os.files(path.join(module_fullpath, "**.lua"))
    if modulefiles then
        for _, modulefile in ipairs(modulefiles) do
            local result, errors = core_sandbox_module._loadfile(modulefile, opt.instance)
            if not result then
                return nil, errors
            end

            -- bind main entry
            if type(result) == "table" and result.main then
                setmetatable(result, { __call = function (_, ...) return result.main(...) end})
            end

            -- get the module path
            local modulepath = path.relative(modulefile, module_fullpath)
            if not modulepath then
                return nil, string.format("cannot get the path for module: %s", module_subpath)
            end
            module = module or {}
            script = errors

            -- save module
            local scope = module
            for _, modulename in ipairs(path.split(modulepath)) do
                local pos = modulename:find(".lua", 1, true)
                if pos then
                    modulename = modulename:sub(1, pos - 1)
                    assert(modulename)
                    scope[modulename] = result
                else
                    -- enter submodule
                    scope[modulename] = scope[modulename] or {}
                    scope = scope[modulename]
                end
            end
        end
    end
    return module, script
end

-- build module
function core_sandbox_module._build_module(module_fullpath)
    local projectdir = path.normalize(path.absolute(module_fullpath))
    local programdir = path.normalize(os.programdir())
    local modulehash = hash.uuid4(projectdir):split("-", {plain = true})[1]:lower()
    local buildir
    if projectdir:startswith(programdir) then
        buildir = path.join(global.directory(), "cache", "modules", modulehash)
    elseif os.isfile(os.projectfile()) then
        buildir = path.join(config.directory(), "cache", "modules", modulehash)
    else
        buildir = path.join(projectdir, "cache", "modules", modulehash)
    end
    local envs = {XMAKE_CONFIGDIR = buildir}
    local argv = {"config", "-P", projectdir, "-o", buildir}
    os.execv(os.programfile(), argv, {envs = envs, curdir = projectdir})
    argv = {"-P", projectdir}
    os.execv(os.programfile(), argv, {envs = envs, curdir = projectdir})
    return buildir
end

-- load module from the binary module
function core_sandbox_module._load_from_binary(module_fullpath, opt)
    local module
    local module_bindir = core_sandbox_module._build_module(module_fullpath)
    local binaryfiles = os.files(path.join(module_bindir, "module_*"))
    if binaryfiles then
        module = {}
        for _, binaryfile in ipairs(binaryfiles) do
            local modulename = path.basename(binaryfile):sub(8)
            module[modulename] = function (...)
                local argv = {}
                for _, arg in ipairs(table.pack(...)) do
                    table.insert(argv, tostring(arg))
                end
                local ok, outdata, errdata, errors = os.iorunv(binaryfile, argv)
                if ok then
                    return outdata
                else
                    if not errors then
                        errors = errdata or ""
                        if #errors:trim() == 0 then
                            errors = outdata or ""
                        end
                    end
                    os.raise({errors = errors, stderr = errdata, stdout = outdata})
                end
            end
        end
    end
    return module
end

-- load module from the shared module
function core_sandbox_module._load_from_shared(module_fullpath, opt)
    local script
    local module
    local module_bindir = core_sandbox_module._build_module(module_fullpath)
    local libraryfiles = os.files(path.join(module_bindir, "module_*"))
    if libraryfiles then
        module = {}
        for _, libraryfile in ipairs(libraryfiles) do
            local modulename = path.basename(binaryfile):sub(8)
            script, errors = package.loadlib(libraryfile, "luaopen_" .. modulename)
            if not script then
                return nil, errors
            end
            module[modulename] = script()
        end
    end
    return module, script
end

-- load module
function core_sandbox_module._load(dir, name, opt)
    opt = opt or {}
    assert(dir and name)

    -- get module subpath
    local module_subpath = core_sandbox_module._modulepath(name)
    assert(module_subpath)

    -- get module full path
    local module_fullpath = path.join(dir, module_subpath)

    -- load module
    local script
    local module
    local modulekind = opt.modulekind
    if modulekind == MODULE_KIND_LUAFILE then
        module, script = core_sandbox_module._load_from_scriptfile(module_fullpath, opt)
    elseif modulekind == MODULE_KIND_LUADIR then
        module, script = core_sandbox_module._load_from_scriptdir(module_fullpath, opt)
    elseif modulekind == MODULE_KIND_BINARY then
        module, script = core_sandbox_module._load_from_binary(module_fullpath, opt)
    elseif modulekind == MODULE_KIND_SHARED then
        module, script = core_sandbox_module._load_from_shared(module_fullpath, opt)
    end
    if not module then
        local errors = script
        return nil, errors or string.format("module: %s not found!", name)
    end
    return module, script
end

-- find and load module
function core_sandbox_module._find_and_load(name, opt)
    opt = opt or {}
    local found = false
    local errors = nil
    local module = nil
    local modulekey = nil
    local modulekind = MODULE_KIND_LUAFILE
    local modules = opt.modules
    local modules_directories = opt.modules_directories
    local loadnext = false
    for idx, moduledir in ipairs(modules_directories) do
        modulekey, modulekind = core_sandbox_module._find(moduledir, name)
        if modulekey then
            local moduleinfo = modules[modulekey]
            if moduleinfo and not opt.nocache and not opt.inherit then
                module = moduleinfo[1]
                errors = moduleinfo[2]
            else
                module, errors = core_sandbox_module._load(moduledir, name, {
                                                           instance = idx < #modules_directories and opt.instance or nil,  -- last modules need not fork sandbox
                                                           module = module,
                                                           modulekind = modulekind})
                if not opt.nocache then
                    modules[modulekey] = {module, errors}
                end
            end
            if module and modulekind == MODULE_KIND_LUADIR then
                loadnext = true
            end
            found = true
            if not loadnext then
                break
            end
        end
    end
    return found, module, errors
end

-- get module name
function core_sandbox_module.name(name)
    local i = name:lastof(".", true)
    if i then
        name = name:sub(i + 1)
    end
    return name
end

-- get module directories
function core_sandbox_module.directories()
    local moduledirs = memcache.get("core_sandbox_module", "moduledirs")
    if not moduledirs then
        moduledirs = { path.join(global.directory(), "modules"),
                       path.join(os.programdir(), "modules"),
                       path.join(os.programdir(), "core/sandbox/modules/import")}
        local modulesdir = os.getenv("XMAKE_MODULES_DIR")
        if modulesdir and os.isdir(modulesdir) then
            table.insert(moduledirs, 1, modulesdir)
        end
        memcache.set("core_sandbox_module", "moduledirs", moduledirs)
    end
    return moduledirs
end

-- add module directories
function core_sandbox_module.add_directories(...)
    local moduledirs = core_sandbox_module.directories()
    for _, dir in ipairs({...}) do
        table.insert(moduledirs, 1, dir)
    end
    memcache.set("core_sandbox_module", "moduledirs", table.unique(moduledirs))
end

-- find module
function core_sandbox_module.find(name)
    for _, moduledir in ipairs(core_sandbox_module.directories()) do
        if (core_sandbox_module._find(moduledir, name)) then
            return true
        end
    end
end

-- import module
--
-- @param name      the module name, e.g. core.platform
-- @param opt       the argument options, e.g. {alias = "", nolocal = true, rootdir = "", try = false, inherit = false, anonymous = false, nocache = false}
--
-- @return          the module instance
--
-- e.g.
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
-- => only return imported module
--
-- import("core.project.config", {try = true})
-- => cannot raise errors if the imported module not found
--
-- @note the polymiorphism is not supported for import.inherit mode now.
--
function core_sandbox_module.import(name, opt)

    -- check
    assert(name)

    -- the argument options
    opt = opt or {}

    -- init module cache
    core_sandbox_module._MODULES = core_sandbox_module._MODULES or {}
    local modules = core_sandbox_module._MODULES

    -- get the parent scope
    local scope_parent = getfenv(2)
    assert(scope_parent)

    -- get module name
    local modulename = core_sandbox_module.name(name)
    if not modulename then
        raise("cannot get module name for %s", name)
    end

    -- the imported name
    local imported_name = opt.alias or modulename

    -- get the current sandbox instance
    local instance = sandbox.instance()
    assert(instance)

    -- the root directory for this sandbox script
    local rootdir = opt.rootdir or instance:rootdir()

    -- init module directories (disable local packages?)
    local modules_directories = (opt.nolocal or not rootdir) and core_sandbox_module.directories() or table.join(rootdir, core_sandbox_module.directories())

    -- load module
    local loadopt = table.clone(opt) or {}
    loadopt.instance = instance
    loadopt.modules = modules
    loadopt.modules_directories = modules_directories
    local found, module, errors = core_sandbox_module._find_and_load(name, loadopt)

    -- not found? attempt to load module.interface
    if not found and not opt.inherit then
        -- get module name
        local found2 = false
        local errors2 = nil
        local module2_name = nil
        local interface_name = nil
        local pos = name:lastof('.', true)
        if pos then
            module2_name = name:sub(1, pos - 1)
            interface_name = name:sub(pos + 1)
        end

        -- load module.interface
        if module2_name and interface_name then
            found2, module2, errors2 = core_sandbox_module._find_and_load(module2_name, loadopt)
            if found2 and module2 and module2[interface_name] then
                module = module2[interface_name]
                found = true
                errors = nil
            else
                errors = errors2
            end
        end
    end

    -- not found?
    if not found then
        if opt.try then
            return nil
        else
            raise("cannot import module: %s, not found!", name)
        end
    end

    -- check
    if not module then
        raise("cannot import module: %s, %s", name, errors)
    end

    -- get module script
    local script = errors

    -- inherit?
    if opt.inherit then

        -- inherit this module into the parent scope
        table.inherit2(scope_parent, module)

        -- import as super module
        imported_name = "_super"

        -- public the script scope for the super module
        --
        -- we can access the all scope members of _super in the child module
        --
        -- e.g.
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
    if type(module) == "table" and module.main then
        setmetatable(module, { __call = function (_, ...) return module.main(...) end})
    end

    -- import this module into the parent scope
    if not opt.anonymous then
        scope_parent[imported_name] = module
    end

    -- return it
    return module
end

-- inherit module
--
-- we can access all super interfaces by _super
--
-- @note the polymiorphism is not supported for import.inherit mode now.
--
function core_sandbox_module.inherit(name, opt)

    -- init opt
    opt = opt or {}

    -- mark as inherit
    opt.inherit = true

    -- import and inherit it
    return core_sandbox_module.import(name, opt)
end

-- get the public object in the current module
function core_sandbox_module.get(name)

    -- is private object?
    if name:startswith('_') then
        return
    end

    -- get the parent scope
    local scope_parent = getfenv(2)
    assert(scope_parent)

    -- get it
    return scope_parent[name]
end

-- load module
return core_sandbox_module

