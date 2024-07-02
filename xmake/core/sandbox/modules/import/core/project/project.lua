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
-- @file        project.lua
--

-- define module
local sandbox_core_project = sandbox_core_project or {}

-- load modules
local table       = require("base/table")
local deprecated  = require("base/deprecated")
local utils       = require("base/utils")
local baseoption  = require("base/option")
local config      = require("project/config")
local option      = require("project/option")
local project     = require("project/project")
local sandbox     = require("sandbox/sandbox")
local raise       = require("sandbox/modules/raise")
local environment = require("platform/environment")
local package     = require("package/package")
local import      = require("sandbox/modules/import")

-- export some readonly interfaces
sandbox_core_project.get                  = project.get
sandbox_core_project.extraconf            = project.extraconf
sandbox_core_project.rule                 = project.rule
sandbox_core_project.rules                = project.rules
sandbox_core_project.toolchain            = project.toolchain
sandbox_core_project.toolchains           = project.toolchains
sandbox_core_project.target               = project.target
sandbox_core_project.target_add           = project.target_add
sandbox_core_project.targets              = project.targets
sandbox_core_project.ordertargets         = project.ordertargets
sandbox_core_project.option               = project.option
sandbox_core_project.options              = project.options
sandbox_core_project.rootfile             = project.rootfile
sandbox_core_project.allfiles             = project.allfiles
sandbox_core_project.rcfiles              = project.rcfiles
sandbox_core_project.directory            = project.directory
sandbox_core_project.name                 = project.name
sandbox_core_project.modes                = project.modes
sandbox_core_project.default_arch         = project.default_arch
sandbox_core_project.allowed_modes        = project.allowed_modes
sandbox_core_project.allowed_plats        = project.allowed_plats
sandbox_core_project.allowed_archs        = project.allowed_archs
sandbox_core_project.mtimes               = project.mtimes
sandbox_core_project.version              = project.version
sandbox_core_project.required_package     = project.required_package
sandbox_core_project.required_packages    = project.required_packages
sandbox_core_project.requires_str         = project.requires_str
sandbox_core_project.requireconfs_str     = project.requireconfs_str
sandbox_core_project.requireslock         = project.requireslock
sandbox_core_project.requireslock_version = project.requireslock_version
sandbox_core_project.policy               = project.policy
sandbox_core_project.tmpdir               = project.tmpdir
sandbox_core_project.tmpfile              = project.tmpfile
sandbox_core_project.is_loaded            = project.is_loaded
sandbox_core_project.apis                 = project.apis

-- check project options
function sandbox_core_project.check_options()

    -- get project options
    local options = {}
    for _, opt in pairs(project.options()) do
        table.insert(options, opt)
    end

    -- get sandbox instance
    local instance = sandbox.instance()
    assert(instance)

    -- enter the project directory
    local oldir, errors = os.cd(os.projectdir())
    if not oldir then
        raise(errors)
    end

    -- init check task
    local checked   = {}
    local checktask = function (index)
        local opt = options[index]
        if opt then
            -- check deps of this option first
            for _, dep in ipairs(opt:orderdeps()) do
                if not checked[dep:name()] then
                    dep:check()
                    checked[dep:name()] = true
                end
            end
            -- check this option
            if not checked[opt:name()] then
                opt:check()
                checked[opt:name()] = true
            end
        end
    end

    -- check all options
    local jobs = baseoption.get("jobs") or os.default_njob()
    import("async.runjobs", {anonymous = true})("check_options", instance:fork(checktask):script(), {total = #options, comax = jobs})

    -- save all options to the cache file
    option.save()

    -- leave the project directory
    local ok, errors = os.cd(oldir)
    if not ok then
        raise(errors)
    end
end

-- config target
function sandbox_core_project._config_target(target, opt)
    for _, rule in ipairs(table.wrap(target:orderules())) do
        local on_config = rule:script("config")
        if on_config then
            on_config(target, opt)
        end
    end
    local on_config = target:script("config")
    if on_config then
        on_config(target, opt)
    end
end

-- config targets
--
-- @param opt   the extra option, e.g. {recheck = false}
--
-- on_config(target, opt)
--    -- @see https://github.com/xmake-io/xmake/issues/4173#issuecomment-1712843956
--    if opt.recheck then
--        target:has_cfuncs(...)
--    end
-- end
--
function sandbox_core_project._config_targets(opt)
    opt = opt or {}
    for _, target in ipairs(table.wrap(project.ordertargets())) do
        if target:is_enabled() then
            sandbox_core_project._config_target(target, opt)
        end
    end
end

-- load rules in the required packages for target
function sandbox_core_project._load_package_rules_for_target(target)
    for _, rulename in ipairs(table.wrap(target:get("rules"))) do
        local packagename = rulename:match("@(.-)/")
        if packagename then
            local pkginfo = project.required_package(packagename)
            if pkginfo then
                local r = pkginfo:rule(rulename)
                if r then
                    target:rule_add(r)
                    for _, dep in pairs(table.wrap(r:deps())) do
                        target:rule_add(dep)
                    end
                end
            end
        end
    end
end

-- load rules in the required packages for targets
-- @see https://github.com/xmake-io/xmake/issues/2374
--
-- @code
-- add_requires("zlib", {system = false})
-- target("test")
--    set_kind("binary")
--    add_files("src/*.cpp")
--    add_packages("zlib")
--    add_rules("@zlib/test")
-- @endcode
--
function sandbox_core_project._load_package_rules_for_targets()
    for _, target in ipairs(table.wrap(project.ordertargets())) do
        if target:is_enabled() then
            sandbox_core_project._load_package_rules_for_target(target)
        end
    end
end

-- load project targets
function sandbox_core_project.load_targets(opt)
    local loaded = sandbox_core_project._LOADED
    if not loaded then
        sandbox_core_project._LOADED = true
        sandbox_core_project._load_package_rules_for_targets()
        sandbox_core_project._config_targets(opt)
    end
end

-- get the filelock of the whole project directory
function sandbox_core_project.filelock()
    local filelock, errors = project.filelock()
    if not filelock then
        raise("cannot create the project lock, %s!", errors or "unknown errors")
    end
    return filelock
end

-- lock the whole project
function sandbox_core_project.lock(opt)
    if sandbox_core_project.trylock(opt) then
        return true
    elseif baseoption.get("diagnosis") then
        utils.cprint("${color.warning}the current project is being accessed by other processes, please wait!")
        io.flush()
    end
    local ok, errors = sandbox_core_project.filelock():lock(opt)
    if not ok then
        raise(errors)
    end
end

-- trylock the whole project
function sandbox_core_project.trylock(opt)
    return sandbox_core_project.filelock():trylock(opt)
end

-- unlock the whole project
function sandbox_core_project.unlock()
    local ok, errors = sandbox_core_project.filelock():unlock()
    if not ok then
        raise(errors)
    end
end

-- change project file and directory (xmake.lua)
function sandbox_core_project.chdir(projectdir, projectfile)
    if not projectfile then
        projectfile = path.join(projectdir, "xmake.lua")
    end
    xmake._PROJECT_FILE = projectfile
    xmake._PROJECT_DIR = path.directory(projectfile)
    xmake._WORKING_DIR = xmake._PROJECT_DIR
    config._DIRECTORY = nil
end

-- get scope
function sandbox_core_project.scope(scopename)
    local cachekey = "scope." .. scopename
    local scope = project._memcache():get(cachekey)
    if not scope then

        -- load the project file first if has not been loaded?
        local ok, errors = project._load()
        if not ok then
            raise("load project failed, %s", errors or "unknown")
        end

        -- load scope
        scope, errors = project._load_scope(scopename, true, false)
        if not scope then
            raise("load scope(%s) failed, %s", scopename, errors or "unknown")
        end
        project._memcache():set(cachekey, scope)
    end
    return scope
end

-- return module
return sandbox_core_project
