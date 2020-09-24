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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("core.project.project")
import("core.platform.platform")
import("core.project.cache")
import("lib.detect.cache", {alias = "detectcache"})
import("scangen")
import("menuconf", {alias = "menuconf_show"})
import("configfiles", {alias = "generate_configfiles"})
import("configheader", {alias = "generate_configheader"})
import("actions.require.install", {alias = "install_requires", rootdir = os.programdir()})

-- filter option
function _option_filter(name)
    local options =
    {
        target      = true
    ,   file        = true
    ,   root        = true
    ,   yes         = true
    ,   quiet       = true
    ,   confirm     = true
    ,   project     = true
    ,   verbose     = true
    ,   diagnosis   = true
    ,   require     = true
    }
    return not options[name]
end

-- host changed?
function _host_changed()
    return os.host() ~= config.read("host")
end

-- need check
function _need_check(changed)

    -- clean?
    if not changed then
        changed = option.get("clean")
    end

    -- get the current mtimes
    local mtimes = project.mtimes()

    -- get the previous mtimes
    local configcache = cache("local.config")
    if not changed then
        local mtimes_prev = configcache:get("mtimes")
        if mtimes_prev then

            -- check for all project files
            for file, mtime in pairs(mtimes) do

                -- modified? reconfig and rebuild it
                local mtime_prev = mtimes_prev[file]
                if not mtime_prev or mtime > mtime_prev then
                    changed = true
                    break
                end
            end
        end
    end

    -- xmake has been updated? force to check config again
    -- we need clean the dirty config cache of the old version
    if not changed then
        if os.mtime(path.join(os.programdir(), "core", "main.lua")) > os.mtime(config.filepath()) then
            changed = true
        end
    end

    -- update mtimes
    configcache:set("mtimes", mtimes)

    -- changed?
    return changed
end

-- check dependent target
function _check_target_deps(target)

    -- check
    for _, depname in ipairs(target:get("deps")) do

        -- check dependent target name
        assert(depname ~= target:name(), "the target(%s) cannot depend self!", depname)

        -- get dependent target
        local deptarget = project.target(depname)

        -- check dependent target name
        assert(deptarget, "unknown target(%s) for %s.deps!", depname, target:name())

        -- check the dependent targets
        _check_target_deps(deptarget)
    end
end

-- check target
function _check_target(targetname)
    assert(targetname)
    if targetname == "all" then
        for _, target in pairs(project.targets()) do
            _check_target_deps(target)
        end
    else
        local target = project.target(targetname)
        assert(target, "unknown target: %s", targetname)
        _check_target_deps(target)
    end
end

-- main entry
function main()

    -- avoid to run this task repeatly
    if _g.configured then return end
    _g.configured = true

    -- scan project and generate it if xmake.lua not exists
    local autogen = false
    local trybuild = option.get("trybuild")
    if not os.isfile(project.rootfile()) and not trybuild then
        autogen = utils.confirm({default = false, description = "xmake.lua not found, try generating it"})
        if autogen then
            scangen()
        else
            os.exit()
        end
    end

    -- check the working directory
    if not option.get("project") and not option.get("file") and os.isdir(os.projectdir()) then
        if path.translate(os.projectdir()) ~= path.translate(os.workingdir()) then
            utils.warning([[You are working in the project directory(%s) and you can also
force to build in current directory via run `xmake -P .`]], os.projectdir())
        end
    end

    -- lock the whole project
    project.lock()

    -- enter menu config
    if option.get("menu") then
        menuconf_show()
    end

    -- the target name
    local targetname = option.get("target") or "all"

    -- get config cache
    local configcache = cache("local.config")

    -- load the project configure
    --
    -- priority: option > option_cache > global > option_default > config_check > project_check > config_cache
    --

    -- get the options
    local options = nil
    for name, value in pairs(option.options()) do
        if _option_filter(name) then
            options = options or {}
            options[name] = value
        end
    end

    -- override configure from the options or cache
    local options_changed = false
    local options_history = {}
    if not option.get("clean") and not autogen then
        options_history = configcache:get("options") or {}
        options = options or options_history
    end
    for name, value in pairs(options) do

        -- options is changed by argument options?
        options_changed = options_changed or options_history[name] ~= value

        -- @note override it and mark as readonly (highest priority)
        config.set(name, value, {readonly = true})
    end

    -- merge the cached configure
    --
    -- @note we cannot load cache config when switching platform, arch ..
    -- so we need known whether options have been changed
    --
    local configcache_loaded = false
    if not options_changed and not option.get("clean") and not _host_changed() then
        configcache_loaded = config.load()
    end

    -- merge the global configure
    for name, value in pairs(global.options()) do
        if config.get(name) == nil then
            config.set(name, value)
        end
    end

    -- merge the default options
    for name, value in pairs(option.defaults()) do
        if _option_filter(name) and config.get(name) == nil then
            config.set(name, value)
        end
    end

    -- merge the project options after default options
    for name, value in pairs(project.get("config")) do
        value = table.unwrap(value)
        assert(type(value) == "string" or type(value) == "boolean" or type(value) == "number", "set_config(%s): unsupported value type(%s)", name, type(value))
        if not config.readonly(name) then
            config.set(name, value)
        end
    end

    -- merge the checked configure
    local recheck = _need_check(options_changed or not configcache_loaded or autogen)
    if recheck then

        -- clear detect cache
        detectcache.clear()

        -- check configure
        config.check()

        -- check project options
        if not trybuild then
            project.check()
        end
    end

    -- load platform
    platform.load(config.plat())

    -- translate the build directory
    local buildir = config.get("buildir")
    if buildir and path.is_absolute(buildir) then
        config.set("buildir", path.relative(buildir, project.directory()), {readonly = true, force = true})
    end

    -- only config for building project using third-party buildsystem
    if not trybuild then

        -- install and update requires and config header
        local require_enable = option.boolean(option.get("require"))
        if (recheck or require_enable) and require_enable ~= false then
            install_requires()
        end

        -- check target and ensure to load all targets, @note we must load targets after installing required packages,
        -- otherwise has_package() will be invalid.
        _check_target(targetname)

        -- update the config header
        if recheck then
            generate_configfiles()
            generate_configheader()
        end
    end

    -- dump config
    if option.get("verbose") then
        config.dump()
    end

    -- save options and configure for the given target
    config.save()
    configcache:set("options", options)

    -- flush config cache
    configcache:flush()

    -- unlock the whole project
    project.unlock()
end
