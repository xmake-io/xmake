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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        addon.lua
--

-- define module
local addon = addon or {}

-- load modules
local os     = require("base/os")
local io     = require("base/io")
local path   = require("base/path")
local table  = require("base/table")
local utils  = require("base/utils")
local global = require("base/global")

-- the payload directories of an addon
--
-- an addon can provide any subset of them, e.g. only `plugins`
--
-- @note only `plugins` is activated for now, the others are reserved
--
function addon._payloaddirs()
    return {"plugins", "rules", "toolchains", "platforms", "modules", "templates", "themes", "includes"}
end

-- the manifest file of an addon, e.g. <sourcedir>/addon.lua
--
-- an addon describes itself in this file, so its name and layout never depend on
-- the package name of the repository which distributes it
--
function addon._manifestfile(sourcedir)
    return path.join(sourcedir, "addon.lua")
end

-- the interpreter of the addon manifest
function addon._interpreter()
    local interp = addon._INTERPRETER
    if interp == nil then
        -- we need to load it lazily, the interpreter also depends on this module
        local interpreter = require("base/interpreter")
        interp = interpreter.new()
        interp:api_define(addon.apis())
        addon._INTERPRETER = interp
    end
    return interp
end

-- the registry file of the installed addons, e.g. ~/.xmake/addons/addons.conf
--
-- we save all installed addons to this file when installing/removing them,
-- so we do not need to scan the whole addons directory on startup
--
function addon._registryfile()
    return path.join(addon.installdir(), "addons.conf")
end

-- save the given addons to the registry file
function addon._save(addons)
    addon._ADDONS = addons
    local registryfile = addon._registryfile()
    -- we need not create an empty registry file if no addons are installed
    if next(addons) == nil and not os.isfile(registryfile) then
        return
    end
    local ok, errors = io.save(registryfile, addons)
    if not ok then
        utils.warning(errors)
    end
end

-- get the payload directory of the given addon
--
-- @param name  the addon name, e.g. "esp32"
-- @param kind  the payload kind, e.g. "rules", "modules"
-- @return      the directory, e.g. ~/.xmake/addons/esp32/v1.0.0/rules
--
function addon._payloaddir(name, kind)
    local dirname = addon.dirname(name)
    local addoninfo = addon.addons()[dirname]
    if addoninfo and table.contains(addoninfo.payloads or {}, kind) then
        return path.join(addon.installdir(), dirname, addoninfo.version, kind)
    end
end

-- get the plugin task names of the given addon directory
--
-- the plugins are not namespaced, we need them to check the conflicts
--
function addon._plugins_of(addondir)
    local plugins = {}
    for _, filepath in ipairs(os.files(path.join(addondir, "plugins", "*", "xmake.lua"))) do
        local content = io.readfile(filepath)
        if content then
            for taskname in content:gmatch("task%s*%(%s*\"(.-)\"") do
                table.insert(plugins, taskname)
            end
        end
    end
    return plugins
end

-- get the template ids of the given addon directory, e.g. {"c/console"}
--
-- the templates are not namespaced, we need them to check the conflicts
--
function addon._templates_of(addondir)
    local templates = {}
    local templatesdir = path.join(addondir, "templates")
    for _, langdir in ipairs(os.dirs(path.join(templatesdir, "*"))) do
        local lang = path.filename(langdir)
        local accepted = {}
        for _, filepath in ipairs(os.files(path.join(langdir, "**", "xmake.lua"))) do
            local dir = path.directory(filepath)
            local relpath = path.relative(dir, langdir)
            if relpath and relpath ~= "." then
                local nested = false
                for _, root in ipairs(accepted) do
                    if dir:startswith(root .. path.sep()) then
                        nested = true
                        break
                    end
                end
                if not nested then
                    table.insert(accepted, dir)
                    table.insert(templates, lang .. "/" .. (relpath:gsub("[/\\]", ".")))
                end
            end
        end
    end
    return templates
end

-- check the conflicts of the plugins and templates, they are not namespaced
--
-- @param dirname   the addon directory name
-- @param addoninfo the addon information, @see addon.register
--
-- @return          the errors if there are some conflicts
--
function addon._check_conflicts(dirname, addoninfo)
    local kindnames = {plugins = "plugin", templates = "template", globalmodules = "global module"}
    for _, kind in ipairs({"plugins", "templates", "globalmodules"}) do
        for _, name in ipairs(addoninfo[kind] or {}) do
            for otherdirname, otheraddoninfo in pairs(addon.addons()) do
                if otherdirname ~= dirname and table.contains(otheraddoninfo[kind] or {}, name) then
                    return string.format("%s(%s) conflicts, it has been provided by the addon(%s)!\nplease remove one of them, e.g. xmake addon --remove %s",
                        kindnames[kind], name, otherdirname, otherdirname)
                end
            end
        end
    end

    -- the global modules can also conflict with the builtin and the user modules
    for _, name in ipairs(addoninfo.globalmodules or {}) do
        local modulepath = (name:gsub("%.", "/")) .. ".lua"
        for _, moduledir in ipairs({os.programdir(), global.directory()}) do
            if os.isfile(path.join(moduledir, "modules", modulepath)) then
                return string.format("global module(%s) conflicts, it has been provided by %s!\nplease rename it in the addon manifest.",
                    name, moduledir == os.programdir() and "xmake" or path.join(moduledir, "modules"))
            end
        end
    end
end

-- get the addons which depend on the given addon
function addon._parents(name)
    local dirname = addon.dirname(name)
    local parents
    for otherdirname, addoninfo in pairs(addon.addons()) do
        if otherdirname ~= dirname and table.contains(addoninfo.deps or {}, dirname) then
            parents = parents or {}
            table.insert(parents, otherdirname)
        end
    end
    if parents then
        table.sort(parents)
    end
    return parents
end

-- unregister the given addon
function addon._unregister(name)
    local dirname = addon.dirname(name)
    local addons = addon.addons()
    if addons[dirname] then
        addons[dirname] = nil
        addon._save(addons)
    end
end

-- get the apis of the addon manifest
function addon.apis()
    return {
        values = {
            -- addon.set_xxx
            "addon.set_description"
        ,   "addon.set_homepage"
        ,   "addon.set_license"
        ,   "addon.set_sourcedir"
            -- addon.add_xxx
        ,   "addon.add_deps"
        ,   "addon.add_globalmodules"
        }
    }
end

-- get the manifest of the given addon directory
--
-- @param sourcedir the addon source or install directory, which contains `addon.lua`
--
-- @return          the manifest, e.g. {name = "esp32-devel", description = "...", sourcedir = "src", deps = {"serial-tools"}}
--                  it will be nil if this addon does not describe itself
--
function addon.manifest(sourcedir)

    -- we may resolve a lot of `@self` references, so we need to cache them
    local manifests = addon._MANIFESTS
    if manifests == nil then
        manifests = {}
        addon._MANIFESTS = manifests
    end
    local cachekey = path.absolute(sourcedir)
    local cacheinfo = manifests[cachekey]
    if cacheinfo ~= nil then
        return cacheinfo or nil
    end

    local manifestfile = addon._manifestfile(sourcedir)
    if not os.isfile(manifestfile) then
        manifests[cachekey] = false
        return
    end
    local interp = addon._interpreter()
    local ok, errors = interp:load(manifestfile)
    if not ok then
        return nil, errors
    end
    local results, errors = interp:make("addon", true, true)
    if not results then
        return nil, errors
    end
    local manifest
    for name, addoninfo in pairs(results) do
        if manifest then
            return nil, string.format("%s: only one addon() scope is allowed!", manifestfile)
        end
        manifest = {name = name,
                    description = addoninfo:get("description"),
                    homepage = addoninfo:get("homepage"),
                    license = addoninfo:get("license"),
                    sourcedir = addoninfo:get("sourcedir"),
                    deps = table.wrap(addoninfo:get("deps")),
                    globalmodules = table.wrap(addoninfo:get("globalmodules"))}
    end
    if not manifest then
        return nil, string.format("%s: no addon() scope found!", manifestfile)
    end
    manifests[cachekey] = manifest
    return manifest
end

-- the install directory of addons, e.g. ~/.xmake/addons
function addon.installdir()
    return path.join(global.directory(), "addons")
end

-- get the directory name of the given addon name, e.g. "myns::foo" -> "myns_foo"
function addon.dirname(name)
    return (name:lower():gsub("::", "_"))
end

-- is the given reference an addon reference?
--
-- e.g. "@addon/esp32/flash", "@self/flash", "@addon.esp32.sdkconfig", "@self.sdkconfig"
--
function addon.is_reference(reference, sep)
    return reference:startswith("@addon" .. sep) or reference:startswith("@self" .. sep)
end

-- get the addon which owns the given script directory
--
-- it's used to resolve the `@self` references inside an addon,
-- so that the addon code never needs to know its own installed name
--
-- @param scriptdir the script directory, e.g. ~/.xmake/addons/esp32/v1.0.0/rules/flash
--                  it will be the directory of the caller script by default
-- @return          the addon name and its root directory, e.g. esp32, ~/.xmake/addons/esp32/v1.0.0
--
function addon.owner(scriptdir)
    if not scriptdir then
        -- we can get it from the sandbox of the caller script, e.g. the rule script of an addon
        local sandbox = require("sandbox/sandbox")
        local instance = sandbox.instance()
        scriptdir = instance and instance:rootdir()
    end
    if not scriptdir then
        return
    end
    scriptdir = path.absolute(scriptdir)

    -- the installed addons, e.g. ~/.xmake/addons/<name>/<version>/...
    local installdir = path.absolute(addon.installdir())
    if scriptdir:startswith(installdir .. path.sep()) then
        local parts = path.split(path.relative(scriptdir, installdir))
        if #parts >= 2 then
            local addondir = path.join(installdir, parts[1], parts[2])
            -- the registry keeps the raw addon name, the directory name is only
            -- its normalized form, e.g. "myns::foo" -> "myns_foo"
            local addoninfo = addon.addons()[parts[1]]
            return addoninfo and addoninfo.name or parts[1], addondir
        end
        return
    end

    -- the addon source directory, we can also run the addon code in place when developing it
    local dir = scriptdir
    while dir and #dir > 0 do
        -- the addon describes itself? we get its name from the manifest
        local manifest = addon.manifest(dir)
        if manifest then
            return manifest.name, dir
        end
        -- otherwise we can only guess it from the payload directories
        for _, payloaddir in ipairs(addon._payloaddirs()) do
            if os.isdir(path.join(dir, payloaddir)) then
                return path.filename(dir), dir
            end
        end
        local parentdir = path.directory(dir)
        if not parentdir or parentdir == dir then
            break
        end
        dir = parentdir
    end
end

-- resolve the given addon reference to its payload directory
--
-- the addon resources are referenced with the addon name from the outside,
-- and with `@self` from the addon code itself, e.g.
--
-- add_rules("@addon/esp32/flash"), import("@addon.esp32.sdkconfig")   -- from a project
-- add_rules("@self/flash"),        import("@self.sdkconfig")          -- from the addon itself
--
-- @param reference the reference, e.g. "@addon/esp32/flash", "@self.sdkconfig"
-- @param sep       the separator, e.g. "/", "."
-- @param kind      the payload kind, e.g. "rules", "modules"
-- @param opt       the options, e.g. {scriptdir = "..."}, it's used to resolve `@self`
--
-- @return          the reference information and errors,
--                  e.g. {dir = "~/.xmake/addons/esp32/v1.0.0/rules", name = "flash", addon = "esp32"}
--
function addon.resolve_reference(reference, sep, kind, opt)
    opt = opt or {}

    -- resolve the `@self` reference from the addon which owns the current script
    if reference:startswith("@self" .. sep) then
        local name = reference:sub(#("@self" .. sep) + 1)
        if name == "" then
            return nil, string.format("invalid addon reference(%s)!", reference)
        end
        local addonname, addondir = addon.owner(opt.scriptdir)
        if not addondir then
            return nil, string.format("%s: cannot resolve `@self`, it can only be used inside an addon!", reference)
        end
        return {dir = path.join(addondir, kind), name = name, addon = addonname}
    end

    -- resolve the `@addon` reference, the addon name is always required
    local prefix = "@addon" .. sep
    if not reference:startswith(prefix) then
        return
    end
    local pos = reference:find(sep, #prefix + 1, true)
    local addonname = pos and reference:sub(#prefix + 1, pos - 1)
    local name = pos and reference:sub(pos + 1)
    if not addonname or addonname == "" or not name or name == "" then
        return nil, string.format("invalid addon reference(%s), it should be `@addon%s<addon>%s<name>`", reference, sep, sep)
    end
    local payloaddir = addon._payloaddir(addonname, kind)
    if not payloaddir then
        return nil, string.format("%s not found!\nplease install the addon which provides it first: xmake addon --install %s", reference, addonname)
    end
    return {dir = payloaddir, name = name, addon = addonname}
end

-- get all installed addons
--
-- @param opt   the options, e.g. {force = true}, we need it to reload the registry
--              if the addons have been installed by another process
--
-- @return      the addons table, e.g. {["hello-world"] = {version = "latest", payloads = {"plugins"}}}
--
function addon.addons(opt)
    local addons = addon._ADDONS
    if opt and opt.force then
        addons = nil
    end
    if addons == nil then
        addons = {}
        local registryfile = addon._registryfile()
        if os.isfile(registryfile) then
            addons = io.load(registryfile) or {}
        end
        addon._ADDONS = addons
    end
    return addons
end

-- get the install directory of the given addon, e.g. ~/.xmake/addons/<name>/<version>
function addon.addondir(name, version)
    local dirname = addon.dirname(name)
    if version == nil then
        local addoninfo = addon.addons()[dirname]
        if addoninfo == nil then
            return nil
        end
        version = addoninfo.version
    end
    return path.join(addon.installdir(), dirname, version)
end

-- get the modules which the installed addons export as the global modules
--
-- they are declared in the addon manifest, e.g. add_globalmodules("core.tools.esptool"),
-- so that they can be imported with their plain names by the internal calls,
-- e.g. import("core.tools.esptool"), find_tool("esptool")
--
-- @return      the modules table, e.g. {["core.tools.esptool"] = "~/.xmake/addons/esp32/v1.0.0/modules"}
--
function addon.globalmodules()
    local globalmodules = addon._GLOBALMODULES
    if globalmodules == nil then
        globalmodules = {}
        for dirname, addoninfo in pairs(addon.addons()) do
            for _, name in ipairs(addoninfo.globalmodules or {}) do
                globalmodules[name] = path.join(addon.installdir(), dirname, addoninfo.version, "modules")
            end
        end
        addon._GLOBALMODULES = globalmodules
    end
    return globalmodules
end

-- get the payload directories of the given kind from all installed addons
--
-- @param kind  the payload kind, e.g. "plugins", "rules"
-- @return      the directories, e.g. {"~/.xmake/addons/hello-world/latest/plugins"}
--
-- @note we do not check if these directories exist, the callers will just ignore the invalid ones
--
function addon.payloads(kind)
    local payloads = {}
    for _, payloadinfo in ipairs(addon.payloadinfos(kind)) do
        table.insert(payloads, payloadinfo.dir)
    end
    return payloads
end

-- get the payload information of the given kind from all installed addons
--
-- @param kind  the payload kind, e.g. "plugins", "rules"
-- @return      the payload infos, e.g. {{name = "hello-world", version = "latest", dir = "~/.xmake/addons/hello-world/latest/plugins"}}
--
function addon.payloadinfos(kind)
    local payloadinfos = {}
    for name, addoninfo in pairs(addon.addons()) do
        if table.contains(addoninfo.payloads or {}, kind) then
            table.insert(payloadinfos, {
                name = name,
                version = addoninfo.version,
                dir = path.join(addon.installdir(), name, addoninfo.version, kind)})
        end
    end
    table.sort(payloadinfos, function (a, b) return a.name < b.name end)
    return payloadinfos
end

-- get the payload root directory of the given addon source directory
--
-- an addon repository has its own files, e.g. tests, ci scripts and documents,
-- so its payloads can be placed in the `src` subdirectory, and we only install them
--
-- e.g.
--   esp32-devel/src/{plugins,rules,toolchains,templates}   -- with the `src` layout
--   hello-world/{plugins}                                  -- without it, for the simple addons
--
-- @param sourcedir   the addon source directory
-- @return            the payload root directory, it will be nil if no payload is found
--
function addon.payloadroot(sourcedir)

    -- the addon can set its payload root directory explicitly, e.g. set_sourcedir("src")
    local manifest = addon.manifest(sourcedir)
    if manifest and manifest.sourcedir then
        local payloadroot = path.join(sourcedir, manifest.sourcedir)
        if #addon.payloads_of(payloadroot) > 0 then
            return payloadroot
        end
        return
    end

    local srcdir = path.join(sourcedir, "src")
    if #addon.payloads_of(srcdir) > 0 then
        return srcdir
    end
    if #addon.payloads_of(sourcedir) > 0 then
        return sourcedir
    end
end

-- get the payload directories of the given addon directory, e.g. {"plugins", "rules"}
function addon.payloads_of(addondir)
    local payloads = {}
    for _, payloaddir in ipairs(addon._payloaddirs()) do
        if os.isdir(path.join(addondir, payloaddir)) then
            table.insert(payloads, payloaddir)
        end
    end
    return payloads
end

-- get the default on_install script of addon packages
--
-- we only install the payload directories of this addon, e.g. plugins, rules, toolchains, ...
--
function addon.installscript()
    return function (package)
        local sourcedir = os.curdir()

        -- the addon name is its identity, e.g. the install directory, the registry key
        -- and the `@addon/<name>/xxx` references, so the package must be distributed with the same name
        local manifest, errors = addon.manifest(sourcedir)
        if errors then
            os.raise(errors)
        end
        if manifest and addon.dirname(manifest.name) ~= addon.dirname(package:name()) then
            os.raise("addon(%s) does not match the package name(%s) in the repository!\nplease fix the package recipe or the addon manifest.",
                manifest.name, package:name())
        end

        local payloadroot = addon.payloadroot(sourcedir)
        if not payloadroot then
            os.raise("addon(%s): no payload directory found, e.g. plugins!", package:name())
        end
        for _, payloaddir in ipairs(addon.payloads_of(payloadroot)) do
            os.cp(path.join(payloadroot, payloaddir), package:installdir())
        end

        -- we need not install the manifest, the package manifest(manifest.txt) and the addons
        -- registry already have all the information, we just pass it to the registration
        if manifest then
            package:data_set("addon.manifest", manifest)
        end
    end
end

-- register the given installed addon
--
-- @param name      the addon name
-- @param version   the addon version, e.g. "1.0.1", "latest"
-- @param opt       the options, e.g. {description = "...", deps = {"foo"}}
--
-- @note the addon manifest(addon.lua) is only read when installing, everything which
-- is needed later is recorded here, so we never parse it again
--
-- @return          true or false and errors
--
function addon.register(name, version, opt)
    opt = opt or {}
    local dirname = addon.dirname(name)
    local addondir = path.join(addon.installdir(), dirname, version)
    local addoninfo = {version = version,
                       -- we need to keep the raw name, the directory name is only its
                       -- normalized form, e.g. "myns::foo" -> "myns_foo"
                       name = name ~= dirname and name or nil,
                       description = opt.description,
                       deps = opt.deps,
                       -- the deps which the addon itself declares in its manifest, they are
                       -- recorded whenever this addon has one, so that the repositories can
                       -- check that the manifest and the package recipe are kept in sync
                       manifest_deps = opt.manifest_deps,
                       globalmodules = opt.globalmodules,
                       payloads = addon.payloads_of(addondir),
                       plugins = addon._plugins_of(addondir),
                       templates = addon._templates_of(addondir)}

    -- we need to check the conflicts of the plugins and templates first,
    -- they are not namespaced and we do not know which one will be used
    local errors = addon._check_conflicts(dirname, addoninfo)
    if errors then
        return false, errors
    end

    local addons = addon.addons()
    addons[dirname] = addoninfo
    addon._save(addons)
    return true
end

-- remove the given installed addon
--
-- @param name  the addon name
-- @return      true or false and errors
--
function addon.remove(name, opt)
    opt = opt or {}
    local dirname = addon.dirname(name)
    local installdir = path.join(addon.installdir(), dirname)
    if not os.isdir(installdir) then
        return false, string.format("addon(%s) not found!", name)
    end

    -- we cannot remove it if the other addons depend on it
    if not opt.force then
        local parents = addon._parents(name)
        if parents then
            return false, string.format("addon(%s) cannot be removed, it's depended on by the addon(%s)!\nplease remove them first, or pass --force to remove it anyway",
                name, table.concat(parents, ", "))
        end
    end
    -- we need to remove the symlinks first, we cannot remove them recursively,
    -- otherwise the linked files would be removed too
    --
    -- e.g. the user may link the install directory to the addon source directory when developing it
    for _, versiondir in ipairs(os.dirs(path.join(installdir, "*"))) do
        if os.islink(versiondir) then
            os.rmfile(versiondir)
        end
    end
    if os.islink(installdir) then
        return os.rmfile(installdir)
    end

    local ok, errors = os.rm(installdir)
    if not ok then
        return false, errors
    end
    addon._unregister(name)
    return true
end

-- reload the addons registry and the caches which are built from it
--
-- @note we need it if the addons have been installed by another process,
-- e.g. the addons which a project declares, @see core/project/project.lua
--
function addon.reload()
    addon._ADDONS = nil
    addon._MANIFESTS = nil
    addon._GLOBALMODULES = nil
end

-- rescan the install directory and rebuild the registry
--
-- it's only used to repair the registry file, e.g. the user removed some addon directories manually
--
function addon.rescan()
    local oldaddons = addon.addons()
    local addons = {}
    for _, versiondir in ipairs(os.dirs(path.join(addon.installdir(), "*", "*"))) do
        local payloads = addon.payloads_of(versiondir)
        if #payloads > 0 then
            local dirname = path.filename(path.directory(versiondir))
            local version = path.filename(versiondir)
            local oldaddoninfo = oldaddons[dirname]
            local description, deps
            if oldaddoninfo and oldaddoninfo.version == version then
                -- we need to keep them, we cannot get them from the installed payloads
                description = oldaddoninfo.description
                deps = oldaddoninfo.deps
            end
            -- but the packages also install their own manifest, we can reuse it
            local name
            local manifestfile = path.join(versiondir, "manifest.txt")
            if os.isfile(manifestfile) then
                local manifest = io.load(manifestfile)
                if manifest then
                    name = manifest.name ~= dirname and manifest.name or nil
                    description = manifest.description or description
                end
            end
            addons[dirname] = {version = version, name = name or (oldaddoninfo and oldaddoninfo.name),
                               description = description, deps = deps, payloads = payloads,
                               plugins = addon._plugins_of(versiondir), templates = addon._templates_of(versiondir)}
        end
    end
    addon._save(addons)
    return addons
end

-- clear all installed addons
function addon.clear()
    local installdir = addon.installdir()
    if os.isdir(installdir) then
        os.rmdir(installdir)
    end
    addon._ADDONS = {}
    addon._MANIFESTS = nil
    addon._GLOBALMODULES = nil
end

-- return module
return addon
