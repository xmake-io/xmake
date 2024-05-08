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
-- @file        download_packages.lua
--

-- imports
import("core.base.option")
import("core.base.hashset")
import("core.base.scheduler")
import("core.project.project")
import("core.base.tty")
import("async.runjobs")
import("utils.progress")
import("net.fasturl")
import("private.action.require.impl.package")
import("private.action.require.impl.lock_packages")
import("private.action.require.impl.register_packages")
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
            for _, instance in ipairs(packages) do
                -- achive packages by repository
                local reponame = instance:repo() and instance:repo():name() or (instance:is_system() and "system" or "")
                if instance:is_thirdparty() then
                    reponame = instance:name():lower():split("::")[1]
                end
                packages_repo[reponame] = packages_repo[reponame] or {}
                table.insert(packages_repo[reponame], instance)
            end

            -- show tips
            cprint("${bright color.warning}note: ${clear}download these packages (pass -y to skip confirm)?")
            for reponame, packages in pairs(packages_repo) do
                if reponame ~= "" then
                    print("in %s:", reponame)
                end
                local packages_showed = {}
                for _, instance in ipairs(packages) do
                    if not packages_showed[tostring(instance)] then
                        cprint("  ${yellow}->${clear} %s %s ${dim}%s", instance:displayname(), instance:version_str() or "", package.get_configs_str(instance))
                        packages_showed[tostring(instance)] = true
                    end
                end
            end
        end, answer = function ()
            cprint("please input: ${bright}y${clear} (y/n)")
            io.flush()
            return (io.read() or "false"):trim()
        end})

        -- get confirm result
        result = option.boolean(result)
        if type(result) ~= "boolean" then
            result = true
        end
    end
    return result, packages_modified
end

-- should download package?
function _should_download_package(instance)
    _g.package_status_cache = _g.package_status_cache or {}
    local result = _g.package_status_cache[tostring(instance)]
    if result == nil then
        result = package.should_install(instance) or false
        _g.package_status_cache[tostring(instance)] = result
    end
    return result
end

-- download packages
function _download_packages(packages_download)

    -- we need to hide wait characters if is not a tty
    local show_wait = io.isatty()

    -- init downloaded packages
    local packages_downloaded = {}
    for _, instance in ipairs(packages_download) do
        packages_downloaded[tostring(instance)] = false
    end

    -- save terminal mode for stdout, @see https://github.com/xmake-io/xmake/issues/1924
    local term_mode_stdout = tty.term_mode("stdout")

    -- do download
    local progress_helper = show_wait and progress.new() or nil
    local packages_downloading = {}
    local packages_pending = table.copy(packages_download)
    local working_count = 0
    local downloading_count = 0
    runjobs("download_packages", function (index)

        -- fetch a new package
        local instance = nil
        while instance == nil and #packages_pending > 0 do
            instance = packages_pending[1]
            table.remove(packages_pending, 1)
        end
        if instance then
            working_count = working_count + 1
            downloading_count = downloading_count + 1
            packages_downloading[index] = instance

            -- download this package
            action_download(instance, {outputdir = option.get("packagedir"), download_only = true})

            -- reset package status cache
            _g.package_status_cache = nil

            -- next
            downloading_count = downloading_count - 1
            packages_downloading[index] = nil
            packages_downloaded[tostring(instance)] = true

            -- update working count
            working_count = working_count - 1
        end

    end, {total = #packages_download,
          comax = (option.get("verbose") or option.get("diagnosis")) and 1 or 4,
          isolate = true,
          on_timer = function (running_jobs_indices)

        -- do not print progress info if be verbose
        if option.get("verbose") or not show_wait then
            return
        end

        -- make downloading packages list
        local downloading = {}
        for _, index in ipairs(running_jobs_indices) do
            local instance = packages_downloading[index]
            if instance then
                table.insert(downloading, instance:displayname())
            end
        end
        -- we just return it directly if no thing is waited
        -- @see https://github.com/xmake-io/xmake/issues/3535
        if #downloading == 0 and #downloading == 0 then
            return
        end

        -- get waitobjs tips
        local tips = nil
        local waitobjs = scheduler.co_group_waitobjs("download_packages")
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
        cprintf(" .. %s", tips and ("${dim}" .. tips .. "${clear} ") or "")
        progress_helper:write()
    end, exit = function(errors)
        if errors then
            tty.erase_line_to_start().cr()
            io.flush()
        end
    end})
end

-- download packages
function main(requires, opt)
    opt = opt or {}

    -- load packages
    local packages = package.load_packages(requires, opt)

    -- save terminal mode for stdout
    local term_mode_stdout = tty.term_mode("stdout")

    -- filter packages
    local packages_download = {}
    local packages_unsupported = {}
    local packages_unknown = {}
    for _, instance in ipairs(packages) do
        if _should_download_package(instance) then
            if instance:is_supported() then
                if #instance:urls() > 0 then
                    packages_download[tostring(instance)] = instance
                end
                table.insert(packages_download, instance)
            elseif not instance:is_optional() then
                if not instance:exists() and instance:is_system() then
                    table.insert(packages_unknown, instance)
                else
                    table.insert(packages_unsupported, instance)
                end
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

    if has_errors then
        raise()
    end

    -- get user confirm
    local confirm = _get_confirm(packages_download)
    if not confirm then
        return
    end

    -- sort package urls
    _sort_packages_urls(packages_download)

    -- download all required packages from repositories
    _download_packages(packages_download)
    cprint("outputdir: ${bright}%s", option.get("packagedir"))
    cprint("${color.success}install packages ok")
    return packages
end

