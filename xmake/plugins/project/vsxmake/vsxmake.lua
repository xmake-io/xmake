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
-- @author      OpportunityLiu
-- @file        vsxmake.lua
--

-- imports
import("core.base.option")
import("core.base.hashset")
import("vstudio.impl.vsinfo", { rootdir = path.directory(os.scriptdir()) })
import("render")
import("getinfo")
import("core.project.config")
import("core.cache.localcache")

local template_root = path.join(os.programdir(), "scripts", "vsxmake", "vsproj", "templates")
local template_sln = path.join(template_root, "sln", "vsxmake.sln")
local template_vcx = path.join(template_root, "vcxproj", "#target#.vcxproj")

local template_fil = path.join(template_root, "vcxproj.filters", "#target#.vcxproj.filters")
local template_props = path.join(template_root, "Xmake.Custom.props")
local template_targets = path.join(template_root, "Xmake.Custom.targets")
local template_items = path.join(template_root, "Xmake.Custom.items")
local template_itemfil = path.join(template_root, "Xmake.Custom.items.filters")

function _filter_files(files, includeexts, excludeexts)
    local positive = not excludeexts
    local extset = hashset.from(positive and includeexts or excludeexts)
    local f = {}
    for _, file in ipairs(files) do
        local ext = path.extension(file)
        if (positive and extset:has(ext)) or not (positive or extset:has(ext)) then
            table.insert(f, file)
        end
    end
    table.sort(f)
    return f
end

function _buildparams(info, target, default)

    local function getprop(match, opt)
        local i = info
        local r = info[match]
        if target then
            opt = table.join(target, opt)
        end
        for _, k in ipairs(opt) do
            local v = (i._targets or {})[k]
            if v == nil and i._arch_modes then
                v = i._arch_modes[k]
            end
            if v == nil and i._paths then
                v = i._paths[k]
            end
            if v == nil and i._dirs then
                v = i._dirs[k]
            end
            if v == nil and i._deps then
                v = i._deps[k]
            end
            if v == nil and i._groups then
                v = i._groups[k]
            end
            if v == nil and i._group_deps then
                v = i._group_deps[k]
            end
            if v == nil then
                v = i[k]
            end
            if v == nil then
                raise("key '" .. k .. "' not found")
            end
            i = v
            r = i[match] or r
        end

        return r or default
    end

    local function listconfig(args)
        for _, k in ipairs(args) do
            args[k] = true
        end
        local r = {}
        if args.target then
            table.insert(r, info.targets)
        end
        if args.mode then
            table.insert(r, info.modes)
        end
        if args.arch then
            table.insert(r, info.archs)
        end
        if args.group then
            table.insert(r, info.groups)
        end
        if args.group_dep then
            table.insert(r, info.group_deps)
        end
        if args.dir then
            table.insert(r, info._targets[target].dirs)
        end
        if args.dep then
            table.insert(r, info._targets[target].deps)
        end
        if args.filec then
            local files = info._targets[target].sourcefiles
            table.insert(r, _filter_files(files, {".c"}))
        elseif args.filecxx then
            local files = info._targets[target].sourcefiles
            table.insert(r, _filter_files(files, {".cpp", ".cc", ".cxx"}))
        elseif args.filempp then
            local files = info._targets[target].sourcefiles
            table.insert(r, _filter_files(files, {".mpp", ".mxx", ".cppm", ".ixx"}))
        elseif args.filecu then
            local files = info._targets[target].sourcefiles
            table.insert(r, _filter_files(files, {".cu"}))
        elseif args.fileobj then
            local files = info._targets[target].sourcefiles
            table.insert(r, _filter_files(files, {".obj", ".o"}))
        elseif args.filerc then
            local files = info._targets[target].sourcefiles
            table.insert(r, _filter_files(files, {".rc"}))
        elseif args.fileui then -- for qt/.ui
            local files = info._targets[target].sourcefiles
            table.insert(r, _filter_files(files, {".ui"}))
        elseif args.fileqrc then -- for qt/.qrc
            local files = info._targets[target].sourcefiles
            table.insert(r, _filter_files(files, {".qrc"}))
        elseif args.filets then -- for qt/.ts
            local files = info._targets[target].sourcefiles
            table.insert(r, _filter_files(files, {".ts"}))
        elseif args.incc then
            local files = table.join(info._targets[target].headerfiles or {}, info._targets[target].extrafiles)
            table.insert(r, _filter_files(files, nil, {".natvis"}))
        elseif args.incnatvis then
            local files = table.join(info._targets[target].headerfiles or {}, info._targets[target].extrafiles)
            table.insert(r, _filter_files(files, {".natvis"}))
        end
        return r
    end

    return function(match, opt)
        if type(match) == "table" then
            return listconfig(match)
        end
        return getprop(match, opt)
    end
end

function _trycp(file, target, targetname)
    targetname = targetname or path.filename(file)
    local targetfile = path.join(target, targetname)
    if os.isfile(targetfile) then
        dprint("skipped file %s since the file already exists", path.relative(targetfile))
        return
    end
    os.cp(file, targetfile)
end

function _writefileifneeded(file, content)
    if os.isfile(file) and io.readfile(file) == content then
        dprint("skipped file %s since the file has the same content", path.relative(file))
        return
    end
    -- we need utf8 with bom encoding for unicode
    -- @see https://github.com/xmake-io/xmake/issues/1689
    io.writefile(file, content, {encoding = "utf8bom"})
end

-- save plugin arguments for `plugin.vsxmake.autoupdate`
-- @see https://github.com/xmake-io/xmake/issues/1895
function _save_plugin_arguments()
    local vsxmake_cache = localcache.cache("vsxmake")
    for _, name in ipairs({"kind", "modes", "archs", "outputdir"}) do
        vsxmake_cache:set(name, option.get(name))
    end
    vsxmake_cache:save()
end

-- clear cache
function _clear_cache()
    localcache.clear("detect")
    localcache.clear("option")
    localcache.clear("package")
    localcache.clear("toolchain")

    -- force recheck
    localcache.set("config", "recheck", true)

    localcache.save()
end

-- make
function make(version)

    if not version then
        version = tonumber(config.get("vs"))
        if not version then
            return function(outputdir)
                raise("invalid vs version, run `xmake f --vs=20xx`")
            end
        end
    end

    return function(outputdir)

        -- trace
        vprint("using project kind vs%d", version)

        -- check
        assert(version >= 2010, "vsxmake does not support vs version lower than 2010")

        -- get info and params
        local info = getinfo(outputdir, vsinfo(version))
        local paramsprovidersln = _buildparams(info)

        -- write solution file
        local sln = path.join(info.solution_dir, info.slnfile .. ".sln")
        _writefileifneeded(sln, render(template_sln, "#([A-Za-z0-9_,%.%*%(%)]+)#", "@([^@]+)@", paramsprovidersln))

        -- add solution custom file
        _trycp(template_props, info.solution_dir)
        _trycp(template_targets, info.solution_dir)

        for _, target in ipairs(info.targets) do
            local paramsprovidertarget = _buildparams(info, target, "<!-- nil -->")
            local proj_dir = info._targets[target].vcxprojdir

            -- write project file
            local proj = path.join(proj_dir, target .. ".vcxproj")
            _writefileifneeded(proj, render(template_vcx, "#([A-Za-z0-9_,%.%*%(%)]+)#", "@([^@]+)@", paramsprovidertarget))

            local projfil = path.join(proj_dir, target .. ".vcxproj.filters")
            _writefileifneeded(projfil, render(template_fil, "#([A-Za-z0-9_,%.%*%(%)]+)#", "@([^@]+)@", paramsprovidertarget))

            -- add project custom file
            _trycp(template_props, proj_dir)
            _trycp(template_targets, proj_dir)
            _trycp(template_items, proj_dir)
            _trycp(template_itemfil, proj_dir)
        end

        -- clear config and local cache
        _clear_cache()

        -- save plugin arguments for autoupdate
        _save_plugin_arguments()
    end
end
