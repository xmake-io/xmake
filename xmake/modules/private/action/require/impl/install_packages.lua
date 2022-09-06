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
import("utils.progress")
import("net.fasturl")
import("private.action.require.impl.package")
import("private.action.require.impl.lock_packages")
import("private.action.require.impl.register_packages")
import("private.action.require.impl.actions.install", {alias = "action_install"})
import("private.action.require.impl.actions.download", {alias = "action_download"})

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

-- replace modified package
function _replace_package(packages, instance, extinstance)
    for idx, rawinstance in ipairs(packages) do
        if rawinstance == instance then
            packages[idx] = extinstance
        end
        local deps = rawinstance._DEPS
        for name, dep in pairs(deps) do
            if dep == instance then
                deps[name] = nil
                deps[extinstance:name()] = extinstance
                break
            end
        end
        local parents = rawinstance._PARENTS
        for name, parent in pairs(parents) do
            if parent == instance then
                parents[name] = nil
                parents[extinstance:name()] = extinstance
                break
            end
        end
        local orderdeps = rawinstance._ORDERDEPS
        for depidx, dep in ipairs(orderdeps) do
            if dep == instance then
                orderdeps[depidx] = extinstance
                break
            end
        end
        local librarydeps = rawinstance._LIBRARYDEPS
        for depidx, dep in ipairs(librarydeps) do
            if dep == instance then
                librarydeps[depidx] = extinstance
                break
            end
        end
        local plaindeps = rawinstance._PLAINDEPS
        for depidx, dep in ipairs(rawinstance._PLAINDEPS) do
            if dep == instance then
                plaindeps[depidx] = extinstance
                break
            end
        end
    end
end

-- replace modified packages
function _replace_packages(packages, packages_modified)
    for _, package_modified in ipairs(packages_modified) do
        local instance = package_modified.instance
        local extinstance = package_modified.extinstance
        _replace_package(packages, instance, extinstance)
    end
end

-- get user confirm from 3rd package sources
-- @see https://github.com/xmake-io/xmake/issues/1140
function _get_confirm_from_3rd(packages)

    -- get extpackages list
    local extpackages_list = _g.extpackages_list
    if not extpackages_list then
        extpackages_list = {}
        for _, instance in ipairs(packages) do
            local extsources = instance:get("extsources")
            local extsources_extra = instance:extraconf("extsources")
            if extsources then
                local extpackages = package.load_packages(extsources, extsources_extra)
                for _, extinstance in ipairs(extpackages) do
                    table.insert(extpackages_list, {instance = instance, extinstance = extinstance})
                end
            end
        end
        _g.extpackages_list = extpackages_list
    end

    -- no extpackages?
    if #extpackages_list == 0 then
        print("no more packages!")
        return
    end

    -- get confirm result
    local result = utils.confirm({description = function ()
        cprint("${bright color.warning}note: ${clear}select the following 3rd packages")
        for idx, extinstance in ipairs(extpackages_list) do
            local instance = extinstance.instance
            local extinstance = extinstance.extinstance
            cprint("  ${yellow}%d.${clear} %s ${yellow}->${clear} %s %s ${dim}%s",
                idx, extinstance:name(),
                instance:displayname(),
                instance:version_str() or "",
                package.get_configs_str(instance))
        end
    end, answer = function ()
        cprint("please input number list: ${bright}n${clear} (1,2,..)")
        io.flush()
        return (io.read() or "n"):trim()
    end})

    -- get confirmed extpackages
    local confirmed_extpackages = {}
    if result and result ~= "n" then
        for _, idx in ipairs(result:split(',')) do
            idx = tonumber(idx)
            if extpackages_list[idx] then
                table.insert(confirmed_extpackages, extpackages_list[idx])
            end
        end
    end

    -- modify packages
    if #confirmed_extpackages > 0 then
        _replace_packages(packages, confirmed_extpackages)
        return confirmed_extpackages
    end
end

-- get user confirm
function _get_confirm(packages)

    -- no confirmed packages?
    if #packages == 0 then
        return true
    end

    local result
    local packages_modified
    while result == nil do
        -- get confirm result
        result = utils.confirm({default = true, description = function ()

            -- get packages for each repositories
            local packages_repo = {}
            local packages_group = {}
            for _, instance in ipairs(packages) do
                -- achive packages by repository
                local reponame = instance:repo() and instance:repo():name() or (instance:is_system() and "system" or "")
                if instance:is_thirdparty() then
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
            cprint("${bright color.warning}note: ${clear}install or modify (m) these packages (pass -y to skip confirm)?")
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
                                cprint("  ${yellow}%s${clear} %s %s ${dim}%s", idx == 1 and "->" or "   or", package_in_group:displayname(), package_in_group:version_str() or "", package.get_configs_str(package_in_group))
                                packages_showed[tostring(package_in_group)] = true
                            end
                            packages_group[group] = nil
                        else
                            cprint("  ${yellow}->${clear} %s %s ${dim}%s", instance:displayname(), instance:version_str() or "", package.get_configs_str(instance))
                            packages_showed[tostring(instance)] = true
                        end
                    end
                end
            end
        end, answer = function ()
            cprint("please input: ${bright}y${clear} (y/n/m)")
            io.flush()
            return (io.read() or "false"):trim()
        end})

        -- modify to select 3rd packages?
        if result == "m" then
            packages_modified = _get_confirm_from_3rd(packages)
            result = nil
        else
            -- get confirm result
            result = option.boolean(result)
            if type(result) ~= "boolean" then
                result = true
            end
        end
    end
    return result, packages_modified
end

-- show upgraded packages
function _show_upgraded_packages(packages)
    local upgraded_count = 0
    for _, instance in ipairs(packages) do
        local locked_requireinfo = package.get_locked_requireinfo(instance:requireinfo(), {force = true})
        if locked_requireinfo and locked_requireinfo.version and instance:version() and instance:version():gt(locked_requireinfo.version) then
            cprint("  ${color.dump.string}%s${clear}: %s -> ${color.success}%s", instance:displayname(), locked_requireinfo.version, instance:version_str())
            upgraded_count = upgraded_count + 1
        end
    end
    cprint("${bright}%d packages are upgraded!", upgraded_count)
end

-- fetch packages
function _fetch_packages(packages_fetch, installdeps)

    -- init installed packages
    local packages_fetched = {}
    for _, instance in ipairs(packages_fetch) do
        packages_fetched[tostring(instance)] = false
    end

    -- save terminal mode for stdout, @see https://github.com/xmake-io/xmake/issues/1924
    local term_mode_stdout = tty.term_mode("stdout")

    -- do fetch
    local packages_fetching = {}
    local packages_pending = table.copy(packages_fetch)
    local working_count = 0
    local fetching_count = 0
    local parallelize = true
    runjobs("fetch_packages", function (index)

        -- fetch a new package
        local instance = nil
        while instance == nil and #packages_pending > 0 do
            for idx, pkg in ipairs(packages_pending) do

                -- all dependences has been fetched? we fetch it now
                local ready = true
                local dep_not_ready = nil
                for _, dep in pairs(installdeps[tostring(pkg)]) do
                    local fetched = packages_fetched[tostring(dep)]
                    if fetched == false then
                        ready = false
                        dep_not_ready = dep
                        break
                    end
                end

                -- get a package with the ready status
                if ready then
                    instance = pkg
                    table.remove(packages_pending, idx)
                    break
                elseif working_count == 0 then
                    if #packages_pending == 1 and dep_not_ready then
                        raise("package(%s): cannot be fetched, there are dependencies(%s) that cannot be fetched!", pkg:displayname(), dep_not_ready:displayname())
                    elseif #packages_pending == 1 then
                        raise("package(%s): cannot be fetched!", pkg:displayname())
                    end
                end
            end
            if instance == nil and #packages_pending > 0 then
                os.sleep(100)
            end
        end
        if instance then

            -- update working count
            working_count = working_count + 1

            -- disable parallelize?
            if not instance:is_parallelize() then
                parallelize = false
            end
            if not parallelize then
                while fetching_count > 0 do
                    os.sleep(100)
                end
            end
            fetching_count = fetching_count + 1

            -- fetch this package
            packages_fetching[index] = instance
            local oldenvs = os.getenvs()
            instance:envs_enter()
            instance:fetch()
            os.setenvs(oldenvs)

            -- fix terminal mode to avoid some subprocess to change it
            --
            -- @see https://github.com/xmake-io/xmake/issues/1924
            -- https://github.com/xmake-io/xmake/issues/2329
            if term_mode_stdout ~= tty.term_mode("stdout") then
                tty.term_mode("stdout", term_mode_stdout)
            end

            -- next
            parallelize = true
            fetching_count = fetching_count - 1
            packages_fetching[index] = nil
            packages_fetched[tostring(instance)] = true

            -- update working count
            working_count = working_count - 1
        end
        packages_fetching[index] = nil

    end, {total = #packages_fetch,
          comax = (option.get("verbose") or option.get("diagnosis")) and 1 or 4,
          isolate = true})
end

-- should install package?
function _should_install_package(instance)
    _g.package_status_cache = _g.package_status_cache or {}
    local result = _g.package_status_cache[tostring(instance)]
    if result == nil then
        result = package.should_install(instance) or false
        _g.package_status_cache[tostring(instance)] = result
    end
    return result
end

-- install packages
function _install_packages(packages_install, packages_download, installdeps)

    -- we need hide wait characters if is not a tty
    local show_wait = io.isatty()

    -- init installed packages
    local packages_installed = {}
    for _, instance in ipairs(packages_install) do
        packages_installed[tostring(instance)] = false
    end

    -- save terminal mode for stdout, @see https://github.com/xmake-io/xmake/issues/1924
    local term_mode_stdout = tty.term_mode("stdout")

    -- do install
    local progress_helper = show_wait and progress.new() or nil
    local packages_installing = {}
    local packages_downloading = {}
    local packages_pending = table.copy(packages_install)
    local packages_in_group = {}
    local working_count = 0
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
                for _, dep in pairs(installdeps[tostring(pkg)]) do
                    local installed = packages_installed[tostring(dep)]
                    if installed == false or (installed == nil and _should_install_package(dep) and not dep:is_optional()) then
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
                elseif working_count == 0 then
                    if #packages_pending == 1 and dep_not_found then
                        raise("package(%s): cannot be installed, there are dependencies(%s) that cannot be installed!", pkg:displayname(), dep_not_found:displayname())
                    elseif #packages_pending == 1 then
                        raise("package(%s): cannot be installed!", pkg:displayname())
                    end
                end
            end
            if instance == nil and #packages_pending > 0 then
                os.sleep(100)
            end
        end
        if instance then

            -- update working count
            working_count = working_count + 1

            -- only install the first package in same group
            local group = instance:group()
            if not group or not packages_in_group[group] then

                -- disable parallelize?
                if not instance:is_parallelize() then
                    parallelize = false
                end
                if not parallelize then
                    while installing_count > 0 do
                        os.sleep(100)
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
                    if not action_install(instance) then
                        assert(instance:is_precompiled(), "package(%s) should be precompiled", instance:name())
                        -- we need disable built and re-download and re-install it
                        instance:fackback_build()
                        action_download(instance)
                        action_install(instance)
                    end
                end

                -- reset package status cache
                _g.package_status_cache = nil

                -- register it to local cache if it is root required package
                --
                -- @note we need to register the package in time,
                -- because other packages may be used, e.g. toolchain/packages
                if instance:is_toplevel() then
                    register_packages({instance})
                end

                -- mark this group as 'installed' or 'failed'
                if group then
                    packages_in_group[group] = instance:exists() and 1 or -1
                end

                -- next
                parallelize = true
                installing_count = installing_count - 1
                packages_installing[index] = nil
                packages_installed[tostring(instance)] = true
            end

            -- update working count
            working_count = working_count - 1
        end
        packages_installing[index] = nil
        packages_downloading[index] = nil

    end, {total = #packages_install,
          comax = (option.get("verbose") or option.get("diagnosis")) and 1 or 4,
          isolate = true,
          on_timer = function (running_jobs_indices)

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

        -- fix terminal mode to avoid some subprocess to change it
        -- @see https://github.com/xmake-io/xmake/issues/1924
        if term_mode_stdout ~= tty.term_mode("stdout") then
            tty.term_mode("stdout", term_mode_stdout)
        end

        -- trace
        progress_helper:clear()
        tty.erase_line_to_start().cr()
        cprintf("${yellow}  => ")
        if #downloading > 0 then
            cprintf("downloading ${color.dump.string}%s", table.concat(downloading, ", "))
        end
        if #installing > 0 then
            cprintf("%sinstalling ${color.dump.string}%s", #downloading > 0 and ", " or "", table.concat(installing, ", "))
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
        if instance:is_toplevel() and group then
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

-- sort packages for installation dependencies
function _sort_packages_for_installdeps(packages, installdeps, order_packages)
    for _, instance in ipairs(packages) do
        local deps = installdeps[tostring(instance)]
        if deps then
            _sort_packages_for_installdeps(deps, installdeps, order_packages)
        end
        table.insert(order_packages, instance)
    end
end

-- get package installation dependencies
function _get_package_installdeps(packages)
    local installdeps = {}
    local packagesmap = {}
    for _, instance in ipairs(packages) do
        -- we need use alias name first for toolchain/packages
        packagesmap[instance:alias() or instance:name()] = instance
    end
    for _, instance in ipairs(packages) do
        local deps = {}
        if instance:orderdeps() then
            deps = table.copy(instance:orderdeps())
        end
        -- patch toolchain/packages to installdeps, because we need install toolchain package first
        for _, toolchain in ipairs(instance:toolchains()) do
            for _, packagename in ipairs(toolchain:config("packages")) do
                if packagesmap[packagename] ~= instance then -- avoid loop recursion
                    table.insert(deps, packagesmap[packagename])
                end
            end
        end
        installdeps[tostring(instance)] = deps
    end
    return installdeps
end

-- install packages
function main(requires, opt)

    -- init options
    opt = opt or {}

    -- load packages
    local packages = package.load_packages(requires, opt)

    -- get package installation dependencies
    local installdeps = _get_package_installdeps(packages)

    -- sort packages for installdeps
    local order_packages = {}
    _sort_packages_for_installdeps(packages, installdeps, order_packages)
    packages = table.unique(order_packages)

    -- save terminal mode for stdout
    local term_mode_stdout = tty.term_mode("stdout")

    -- fetch and register packages (with system) from local first
    local packages_fetch = {}
    for _, instance in ipairs(packages) do
        if instance and (instance:is_fetchonly() or
                         not option.get("force") or
                         (option.get("shallow") and not instance:is_toplevel())) then
            table.insert(packages_fetch, instance)
        end
    end
    _fetch_packages(packages_fetch, installdeps)

    -- register all installed root packages to local cache
    register_packages(packages)

    -- filter packages
    local packages_install = {}
    local packages_download = {}
    local packages_unsupported = {}
    local packages_not_found = {}
    local packages_unknown = {}
    for _, instance in ipairs(packages) do
        if _should_install_package(instance) then
            if instance:is_supported() then
                if #instance:urls() > 0 then
                    packages_download[tostring(instance)] = instance
                end
                table.insert(packages_install, instance)
            elseif not instance:is_optional() then
                if not instance:exists() and instance:is_system() then
                    table.insert(packages_unknown, instance)
                else
                    table.insert(packages_unsupported, instance)
                end
            end
        -- @see https://github.com/xmake-io/xmake/issues/2050
        elseif not instance:exists() and not instance:is_optional() then
            local requireinfo = instance:requireinfo()
            if requireinfo and requireinfo.system then
                table.insert(packages_not_found, instance)
            end
        end
    end

    -- exists unknown packages?
    local has_errors = false
    if #packages_unknown > 0 then
        cprint("${bright color.warning}note: ${clear}the following packages were not found in any repository (check if they are spelled correctly):")
        for _, instance in ipairs(packages_unknown) do
            print("  -> %s", instance:displayname())
        end
        has_errors = true
    end

    -- exists unsupported packages?
    if #packages_unsupported > 0 then
        cprint("${bright color.warning}note: ${clear}the following packages are unsupported on $(plat)/$(arch):")
        for _, instance in ipairs(packages_unsupported) do
            print("  -> %s %s", instance:displayname(), instance:version_str() or "")
        end
        has_errors = true
    end

    -- exists not found packages?
    if #packages_not_found > 0 then
        cprint("${bright color.warning}note: ${clear}the following packages were not found on your system, try again after installing them:")
        for _, instance in ipairs(packages_not_found) do
            print("  -> %s %s", instance:displayname(), instance:version_str() or "")
        end
        has_errors = true
    end

    if has_errors then
        raise()
    end

    -- get user confirm
    local confirm, packages_modified = _get_confirm(packages_install)
    if not confirm then
        local packages_must = {}
        for _, instance in ipairs(packages_install) do
            if not instance:is_optional() then
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

    -- show upgraded information
    if option.get("upgrade") then
        print("upgrading packages ..")
    end

    -- some packages are modified? we need fix packages list and all deps
    if packages_modified then
        order_packages = {}
        _replace_packages(packages, packages_modified)
        installdeps = _get_package_installdeps(packages)
        _sort_packages_for_installdeps(packages, installdeps, order_packages)
        packages = table.unique(order_packages)
     end

    -- sort package urls
    _sort_packages_urls(packages_download)

    -- install all required packages from repositories
    _install_packages(packages_install, packages_download, installdeps)

    -- disable other packages in same group
    _disable_other_packages_in_group(packages)

    -- re-register and refresh all root packages to local cache,
    -- because there may be some missing optional dependencies reinstalled
    register_packages(packages)

    -- show upgraded packages
    if option.get("upgrade") then
        _show_upgraded_packages(packages)
    end

    -- lock packages
    lock_packages(packages)
    return packages
end

