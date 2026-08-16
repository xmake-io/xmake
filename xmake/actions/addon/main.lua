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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.package.addon")
import("core.project.project")
import("devel.git")
import("private.action.addon.impl.install_addons")
import("private.action.addon.impl.xrepo", {alias = "xrepo_addon"})
import("private.action.require.impl.environment")
import("private.action.require.impl.search_packages")

-- validate an addon directory name
function _check_addon_name(name)
    assert(type(name) == "string" and name ~= "" and name ~= "." and not name:find("..", 1, true) and not name:find("[/\\:]"), "invalid addon name(%s)!", name)
    return name
end

-- get addon directory in ~/.xmake/addons
function _get_addondir(name, version)
    local addondir = addon.installdir()
    if name then
        addondir = path.join(addondir, addon.dirname(_check_addon_name(name)))
        if version then
            addondir = path.join(addondir, version)
        end
    end
    return addondir
end

-- install the given addons from the repositories which provide them
--
-- @note we install them in one shot, xrepo resolves and installs them in parallel
--
function _install_from_repo(names)
    for _, name in ipairs(names) do
        -- e.g. myrepo@myaddon
        _check_addon_name(name:split("@", {plain = true, limit = 2})[2] or name)
    end
    xrepo_addon("install", names, {force = option.get("force")})
end

-- install a single addon from a source directory (as the given name, default to the directory name)
function _install_from_local(dir, name)
    assert(os.isdir(dir), "addon path(%s) not found!", dir)

    -- we need to normalize it first, e.g. `/path/to/myaddon/` -> `/path/to/myaddon`,
    -- otherwise we cannot get the addon name from the directory
    dir = path.normalize(path.absolute(dir))

    -- we only install the payload directories, the addon repository may have its own files,
    -- e.g. tests, ci scripts and documents, and they can also be placed in the `src` subdirectory
    local payloadroot = addon.payloadroot(dir)
    assert(payloadroot, "addon path(%s): no payload directory found, e.g. ${bright}plugins${clear}!", dir)

    -- the addon describes itself? its manifest is always authoritative,
    -- otherwise we can only guess its name from the directory name
    local manifest = addon.manifest(dir)
    if manifest then
        name = manifest.name
    end
    name = name or path.filename(dir)

    -- the addons installed from a local directory or a git url have no semantic version
    local version = "latest"
    local dstdir = _get_addondir(name, version)
    assert(not os.isdir(dstdir), "addon(%s) already exists!", name)

    -- the addons which it depends on are not installed by the local installation,
    -- so we need to install them from the repositories first
    if manifest then
        for _, dep in ipairs(manifest.deps) do
            if not addon.addons()[addon.dirname(dep)] then
                _install_from_repo({dep})
            end
        end
    end

    for _, payloaddir in ipairs(addon.payloads_of(payloadroot)) do
        os.vcp(path.join(payloadroot, payloaddir), path.join(dstdir, payloaddir))
    end

    -- we need to roll back the installed payloads if it cannot be registered, e.g. the name conflicts
    try
    {
        function ()
            addon.register(name, version, manifest and {
                description = manifest.description,
                deps = #manifest.deps > 0 and manifest.deps or nil,
                globalmodules = #manifest.globalmodules > 0 and manifest.globalmodules or nil})
        end,
        catch
        {
            function (errors)
                os.tryrm(dstdir)
                -- we need to remove the addon directory too if no other version is installed
                local addondir = path.directory(dstdir)
                if #os.filedirs(path.join(addondir, "*")) == 0 then
                    os.tryrm(addondir)
                end
                raise(errors)
            end
        }
    }
    cprint("${color.success}install ${bright}%s${clear} ok!", name)
end

-- install a single addon from a git url or github shortcut, e.g. https://github.com/xmake-addons/serial-monitor
function _install_from_git(url)
    local branch
    if url:startswith("github:") then
        local i = url:find("#", 1, true)
        if i then
            branch = url:sub(i + 1)
            url = url:sub(1, i - 1)
        end
        url = git.asgiturl(url)
    end
    local name = (path.filename(url):gsub("%.git$", ""))
    local tmpdir = os.tmpfile() .. ".dir"

    -- we need git to clone it, it will be installed first if it's not found
    --
    -- @note we cannot enter it for the other install paths, it may install packages
    -- and that needs a project, but `xmake addon` can be run anywhere
    --
    environment.enter()
    try
    {
        function ()
            git.clone(url, {verbose = option.get("verbose"), branch = branch, outputdir = tmpdir})
            os.tryrm(path.join(tmpdir, ".git"))
            _install_from_local(tmpdir, name)
        end,
        finally
        {
            -- we always need to remove the temporary clone directory,
            -- @note try() swallows the errors if we do not re-raise them here
            function (ok, errors)
                os.tryrm(tmpdir)
                if not ok then
                    raise(errors)
                end
            end
        }
    }
    environment.leave()
end

-- does the given name come from a repository? e.g. `myaddon`, `myrepo@myaddon`
function _is_from_repo(name)
    -- github shortcut: github:user/repo or github:user/repo#branch
    if name:startswith("github:") then
        return false
    end

    -- local directory
    --
    -- @note we need to check it before the git url, `git.asgiturl` also accepts
    -- the local paths with a trailing separator, e.g. `/path/to/myaddon/`
    if os.isdir(name) then
        return false
    end
    return not git.asgiturl(name)
end

-- install addons
function _install()
    local names = assert(option.get("addons"), "please specify the addons to be installed!")

    -- the addons from the repositories are installed in one shot, the others one by one
    local requires = {}
    for _, name in ipairs(names) do
        if _is_from_repo(name) then
            table.insert(requires, name)
        elseif os.isdir(name) then
            _install_from_local(name)
        else
            _install_from_git(name)
        end
    end
    if #requires > 0 then
        _install_from_repo(requires)
    end
end

-- remove the given installed addons
--
-- @note `xrepo remove --addon` removes them in the same way,
-- @see xmake/modules/private/xrepo/action/remove.lua
--
function _remove()
    local names = option.get("addons")
    local force = option.get("force")

    -- remove all the installed addons? e.g. xmake addon --remove --all
    if option.get("all") then
        names = table.keys(addon.addons())
        if #names == 0 then
            wprint("no installed addons!")
            return
        end
        -- the dependencies between them do not matter, they are all removed
        force = true
    end

    assert(names, "please specify the addon name to be removed!")
    for _, name in ipairs(names) do
        addon.remove(name, {force = force})
        cprint("${color.success}remove ${bright}%s${clear} ok!", name)
    end
end

-- upgrade the addons which the current project declares, e.g. add_addons("esp32-devel 1.0.x")
function _upgrade()
    local declarations = {addons = table.wrap(project.get("addons")),
                          repositories = table.wrap(project.get("repositories"))}
    assert(#declarations.addons > 0, "no addons are declared in this project, e.g. add_addons(\"esp32-devel\")!")
    install_addons(os.projectdir(), declarations, {upgrade = true})
end

-- search the addons from the repositories
function _search()
    local patterns = assert(option.get("addons"), "please specify the addon name pattern to be searched!")
    xrepo_addon("search", patterns)
end

-- collect the installed addons from the addons registry
function _collect_installed_addons()
    local entries = {}
    for name, addoninfo in table.orderpairs(addon.addons()) do
        -- an addon can be installed with several versions, we show the active one,
        -- the projects can lock the other ones, @see core/project/addons.lua
        local versions = addon.versions(name)
        table.insert(entries, {name = name, version = addoninfo.version,
                               versions = #versions > 1 and versions or nil,
                               description = addoninfo.description, payloads = addoninfo.payloads})
    end
    return entries
end

-- print an addon entry, e.g. -> serial-monitor v1.0.1: monitor the serial port output (in xmake-repo)
function _print_addon(entry, suffix)
    local title = entry.name
    if entry.version then
        title = title .. " " .. entry.version
    end
    local description = entry.description and (": " .. entry.description) or ""
    cprint("  ${color.dump.reference}->${clear} ${color.dump.string}%s${clear}%s%s", title, description, suffix or "")
end

-- get the addons in the repositories, we reuse the packages search here
function _collect_repo_addons(exclude)
    local entries = {}
    for _, results in table.orderpairs(search_packages({"*"}, {kind = "addon", description = false})) do
        for _, result in ipairs(results) do
            if not exclude[result.name] then
                table.insert(entries, result)
            end
        end
    end
    table.sort(entries, function (a, b) return a.name < b.name end)
    return entries
end

-- list all addons
function _list()

    -- show the installed addons
    local installed = _collect_installed_addons()
    local exclude = {}
    cprint("${bright}the installed addons:${clear}")
    if #installed > 0 then
        for _, entry in ipairs(installed) do
            exclude[entry.name] = true
            local suffix = string.format(" ${dim}(%s)${clear}", table.concat(entry.payloads, ", "))
            if entry.versions then
                suffix = suffix .. string.format(" ${dim}[installed: %s]${clear}", table.concat(entry.versions, ", "))
            end
            _print_addon(entry, suffix)
        end
    else
        print("  (none)")
    end

    -- show the addons in the repositories, we only show the first ones if there are too many
    local listlimit = 10
    local avail = _collect_repo_addons(exclude)
    cprint("${bright}the available addons:${clear} ${dim}(run `xmake addon --install <name>` to install," ..
           " `--search <pattern>` to search)${clear}")
    if #avail > 0 then
        for idx, entry in ipairs(avail) do
            if idx > listlimit then
                cprint("  ${dim}... and %d more${clear}", #avail - listlimit)
                break
            end
            _print_addon(entry, entry.reponame and string.format(" ${dim}(in %s)${clear}", entry.reponame) or nil)
        end
    else
        print("  (none)")
    end
end

function main()
    if option.get("install") then
        _install()
    elseif option.get("remove") then
        _remove()
    elseif option.get("upgrade") then
        _upgrade()
    elseif option.get("list") then
        _list()
    elseif option.get("search") then
        _search()
    end
end
