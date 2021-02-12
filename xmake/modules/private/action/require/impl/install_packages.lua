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
-- @file        install_packages.lua
--

-- imports
import("core.base.option")
import("core.base.hashset")
import("core.base.scheduler")
import("core.project.project")
import("core.base.tty")
import("private.async.runjobs")
import("private.utils.progress")
import("actions.install", {alias = "action_install"})
import("actions.download", {alias = "action_download"})
import("net.fasturl")
import("private.action.require.impl.package")
import("private.action.require.impl.register_packages")

-- sort packages urls
function _sort_packages_urls(packages)

    -- add all urls to fasturl and prepare to sort them together
    for _, instance in pairs(packages) do
        fasturl.add(instance:urls())
    end

    -- sort and update urls
    for _, instance in pairs(packages) do
        instance:urls_set(fasturl.sort(instance:urls()))
    end
end

-- get package parents string
function _get_package_parents_str(instance)
    local parents = instance:parents()
    if parents then
        local parentnames = {}
        for _, parent in pairs(parents) do
            table.insert(parentnames, parent:displayname())
        end
        if #parentnames == 0 then
            return
        end
        return table.concat(parentnames, ",")
    end
end

-- get package configs string
function _get_package_configs_str(instance)
    local configs = {}
    if instance:optional() then
        table.insert(configs, "optional")
    end
    local requireinfo = instance:requireinfo()
    if requireinfo then
        for k, v in pairs(requireinfo.configs) do
            if type(v) == "boolean" then
                table.insert(configs, k .. ":" .. (v and "y" or "n"))
            else
                table.insert(configs, k .. ":" .. v)
            end
        end
    end
    local parents_str = _get_package_parents_str(instance)
    if parents_str then
        table.insert(configs, "from:" .. parents_str)
    end
    local configs_str = #configs > 0 and "[" .. table.concat(configs, ", ") .. "]" or ""
    local limitwidth = os.getwinsize().width * 2 / 3
    if #configs_str > limitwidth then
        configs_str = configs_str:sub(1, limitwidth) .. " ..)"
    end
    return configs_str
end

-- get user confirm
function _get_confirm(packages)

    -- no confirmed packages?
    if #packages == 0 then
        return true
    end

    -- get confirm
    local confirm = utils.confirm({default = true, description = function ()

        -- get packages for each repositories
        local packages_repo = {}
        local packages_group = {}
        for _, instance in ipairs(packages) do
            -- achive packages by repository
            local reponame = instance:repo() and instance:repo():name() or (instance:isSys() and "system" or "")
            if instance:is3rd() then
                reponame = instance:name():lower():split("::")[1]
            end
            packages_repo[reponame] = packages_repo[reponame] or {}
            table.insert(packages_repo[reponame], instance)

            -- achive packages by group
            local group = instance:group()
            if group then
                packages_group[group] = packages_group[group] or {}
                table.insert(packages_group[group], instance)
            end
        end

        -- show tips
        cprint("${bright color.warning}note: ${clear}try installing these packages (pass -y to skip confirm)?")
        for reponame, packages in pairs(packages_repo) do
            if reponame ~= "" then
                print("in %s:", reponame)
            end
            local packages_showed = {}
            for _, instance in ipairs(packages) do
                if not packages_showed[tostring(instance)] then
                    local group = instance:group()
                    if group and packages_group[group] and #packages_group[group] > 1 then
                        for idx, package_in_group in ipairs(packages_group[group]) do
                            cprint("  ${yellow}%s${clear} %s %s ${dim}%s", idx == 1 and "->" or "   or", package_in_group:displayname(), package_in_group:version_str() or "", _get_package_configs_str(package_in_group))
                            packages_showed[tostring(package_in_group)] = true
                        end
                        packages_group[group] = nil
                    else
                        cprint("  ${yellow}->${clear} %s %s ${dim}%s", instance:displayname(), instance:version_str() or "", _get_package_configs_str(instance))
                        packages_showed[tostring(instance)] = true
                    end
                end
            end
        end
    end})
    return confirm
end

-- install packages
function _install_packages(packages_install, packages_download)

    -- we need hide wait characters if is not a tty
    local show_wait = io.isatty()

    -- do install
    local progress_helper = show_wait and progress.new() or nil
    local packages_installing = {}
    local packages_downloading = {}
    local packages_pending = table.copy(packages_install)
    local packages_in_group = {}
    local installing_count = 0
    local parallelize = true
    runjobs("install_packages", function (index)

        -- fetch a new package
        local instance = nil
        while instance == nil and #packages_pending > 0 do
            for idx, pkg in ipairs(packages_pending) do

                -- all dependences has been installed? we install it now
                local ready = true
                local dep_not_found = nil
                for _, dep in ipairs(pkg:orderdeps()) do
                    if not dep:exists() then
                        ready = false
                        dep_not_found = dep
                        break
                    end
                end
                local group = pkg:group()
                if ready and group then
                    -- this group has been installed? skip it
                    local group_status = packages_in_group[group]
                    if group_status == 1 then
                        table.remove(packages_pending, idx)
                        break
                    -- this group is installing? wait it
                    elseif group_status == 0 then
                        ready = false
                    end
                end

                -- get a package with the ready status
                if ready then
                    instance = pkg
                    table.remove(packages_pending, idx)
                    break
                elseif installing_count == 0 then
                    if #packages_pending == 1 and dep_not_found then
                        raise("package(%s): cannot be installed, there are dependencies(%s) that cannot be installed!", pkg:displayname(), dep_not_found:displayname())
                    elseif #packages_pending == 1 then
                        raise("package(%s): cannot be installed!", pkg:displayname())
                    end
                end
            end
            if instance == nil and #packages_pending > 0 then
                scheduler.co_yield()
            end
        end
        if instance then

            -- only install the first package in same group
            local group = instance:group()
            if not group or not packages_in_group[group] then

                -- disable parallelize?
                if not instance:parallelize() then
                    parallelize = false
                end
                if not parallelize then
                    while installing_count > 0 do
                        scheduler.co_yield()
                    end
                end
                installing_count = installing_count + 1

                -- mark this group as 'installing'
                if group then
                    packages_in_group[group] = 0
                end

                -- download this package first
                local downloaded = true
                if packages_download[tostring(instance)] then
                    packages_downloading[index] = instance
                    downloaded = action_download(instance)
                    packages_downloading[index] = nil
                end

                -- install this package
                packages_installing[index] = instance
                if downloaded then
                    action_install(instance)
                end

                -- register it to local cache if it is root required package
                --
                -- @note we need to register the package in time,
                -- because other packages may be used, e.g. toolchain/packages
                if not instance:parents() then
                    register_packages(instance)
                end

                -- mark this group as 'installed' or 'failed'
                if group then
                    packages_in_group[group] = instance:exists() and 1 or -1
                end

                -- next
                parallelize = true
                installing_count = installing_count - 1
                packages_installing[index] = nil
            end
        end
        packages_installing[index] = nil
        packages_downloading[index] = nil

    end, {total = #packages_install, comax = (option.get("verbose") or option.get("diagnosis")) and 1 or 4, on_timer = function (running_jobs_indices)

        -- do not print progress info if be verbose
        if option.get("verbose") or not show_wait then
            return
        end

        -- make installing and downloading packages list
        local installing = {}
        local downloading = {}
        for _, index in ipairs(running_jobs_indices) do
            local instance = packages_installing[index]
            if instance then
                table.insert(installing, instance:displayname())
            end
            local instance = packages_downloading[index]
            if instance then
                table.insert(downloading, instance:displayname())
            end
        end

        -- get waitobjs tips
        local tips = nil
        local waitobjs = scheduler.co_group_waitobjs("install_packages")
        if waitobjs:size() > 0 then
            local names = {}
            for _, obj in waitobjs:keys() do
                if obj:otype() == scheduler.OT_PROC then
                    table.insert(names, obj:name())
                elseif obj:otype() == scheduler.OT_SOCK then
                    table.insert(names, "sock")
                elseif obj:otype() == scheduler.OT_PIPE then
                    table.insert(names, "pipe")
                end
            end
            names = table.unique(names)
            if #names > 0 then
                names = table.concat(names, ",")
                if #names > 16 then
                    names = names:sub(1, 16) .. ".."
                end
                tips = string.format("(%d/%s)", waitobjs:size(), names)
            end
        end

        -- trace
        progress_helper:clear()
        tty.erase_line_to_start().cr()
        cprintf("${yellow}  => ")
        if #downloading > 0 then
            cprintf("downloading ${magenta}%s", table.concat(downloading, ", "))
        end
        if #installing > 0 then
            cprintf("%sinstalling ${magenta}%s", #downloading > 0 and ", " or "", table.concat(installing, ", "))
        end
        cprintf(" .. %s", tips and ("${dim}" .. tips .. "${clear} ") or "")
        progress_helper:write()
    end, exit = function(errors)
        if errors then
            tty.erase_line_to_start().cr()
            io.flush()
        end
    end})
end

-- only enable the first package in same group and root packages
function _disable_other_packages_in_group(packages)
    local registered_in_group = {}
    for _, instance in ipairs(packages) do
        local group = instance:group()
        if not instance:parents() and group then
            local required_package = project.required_package(instance:alias() or instance:name())
            if required_package then
                if not registered_in_group[group] and required_package:enabled() then
                    registered_in_group[group] = true
                elseif required_package:enabled() then
                    required_package:enable(false)
                    required_package:save()
                end
            end
        end
    end
end

-- install packages
function main(requires, opt)

    -- init options
    opt = opt or {}

    -- load packages
    local packages = package.load_packages(requires, opt)

    -- fetch packages (with system) from local first
    runjobs("fetch_packages", function (index)
        local instance = packages[index]
        if instance and (not option.get("force") or (option.get("shallow") and instance:parents())) then
            instance:envs_enter()
            instance:fetch()
            instance:envs_leave()
        end
    end, {total = #packages})

    -- filter packages
    local packages_install = {}
    local packages_download = {}
    local packages_unsupported = {}
    for _, instance in ipairs(packages) do
        if not instance:exists() then
            if instance:supported() then
                if #instance:urls() > 0 then
                    packages_download[tostring(instance)] = instance
                end
                table.insert(packages_install, instance)
            elseif not instance:optional() then
                table.insert(packages_unsupported, instance)
            end
        end
    end

    -- exists unsupported packages?
    if #packages_unsupported > 0 then
        -- show tips
        cprint("${bright color.warning}note: ${clear}the following packages are unsupported for $(plat)/$(arch)!")
        for _, instance in ipairs(packages_unsupported) do
            print("  -> %s %s", instance:displayname(), instance:version_str() or "")
        end
        raise()
    end

    -- get user confirm
    if not _get_confirm(packages_install) then
        local packages_must = {}
        for _, instance in ipairs(packages_install) do
            if not instance:optional() then
                table.insert(packages_must, instance:displayname())
            end
        end
        if #packages_must > 0 then
            raise("packages(%s): must be installed!", table.concat(packages_must, ", "))
        else
            -- continue other actions
            return
        end
    end

    -- sort package urls
    _sort_packages_urls(packages_download)

    -- install all required packages from repositories
    _install_packages(packages_install, packages_download)

    -- register all required root packages to local cache
    register_packages(packages)

    -- disable other packages in same group
    _disable_other_packages_in_group(packages)
    return packages
end

