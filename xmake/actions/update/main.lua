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
import("core.base.semver")
import("core.base.option")
import("core.base.task")
import("core.base.process")
import("core.base.tty")
import("net.http")
import("devel.git")
import("net.fasturl")
import("core.base.privilege")
import("privilege.sudo")
import("private.async.runjobs")
import("actions.require.impl.environment", {rootdir = os.programdir()})
import("private.action.update.fetch_version")
import("utils.archive")
import("lib.detect.find_file")

-- the installer filename for windows
local win_installer_name = "xmake-installer.exe"

-- run program with privilege
function _sudo_v(program, params)

    -- attempt to install directly
    return try
    {
        function ()
            os.vrunv(program, params)
            return true
        end,

        catch
        {
            -- failed or not permission? request administrator permission and run it again
            function (errors)

                -- trace
                vprint(errors)

                -- try get privilege
                if privilege.get() then
                    local ok = try
                    {
                        function ()
                            os.vrunv(program, params)
                            return true
                        end
                    }

                    -- release privilege
                    privilege.store()

                    -- ok?
                    if ok then
                        return true
                    end
                end

                -- show tips
                local command = program .. " " ..os.args(params)
                cprint("\r${bright color.error}error: ${clear}run `%s` failed, may permission denied!", command)

                -- continue to install with administrator permission?
                if sudo.has() then

                    -- confirm to install?
                    local confirm = utils.confirm({ default = true, description = format("try continue to run `%s` with administrator permission again", command) })
                    if confirm then
                        sudo.vrunv(program, params)
                        return true
                    end
                end
            end
        }
    }
end

-- run program witn admin user
function _run_win_v(program, commands, admin)
    local sudo_vbs = path.join(os.programdir(), "scripts", "run.vbs")
    local temp_vbs = os.tmpfile() .. ".vbs"
    os.cp(sudo_vbs, temp_vbs)
    local params = table.join("/Nologo", temp_vbs, "W" .. (admin and "A" or "N") , program, commands)
    process.openv("cscript", params, {detach = true}):close()
end

-- do uninstall
function _uninstall()
    if is_host("windows") then
        local uninstaller = path.join(os.programdir(), "uninstall.exe")
        if os.isfile(uninstaller) then
            -- UAC on win7
            local params = option.get("quiet") and { "/S" } or {}
            if winos:version():gt("winxp") then
                _run_win_v(uninstaller, params, true)
            else
                _run_win_v(uninstaller, params, false)
            end
        else
            raise("the uninstaller(%s) not found!", uninstaller)
        end
    else
        if os.programdir():startswith("/usr/") then
            _sudo_v("xmake", {"lua", "rm", os.programdir() })
            if os.isfile("/usr/local/bin/xmake") then
                _sudo_v("xmake", {"lua", "rm", "/usr/local/bin/xmake" })
            end
            if os.isfile("/usr/bin/xmake") then
                _sudo_v("xmake", {"lua", "rm", "/usr/bin/xmake" })
            end
        else
            os.rm(os.programdir())
            os.rm(os.programfile())
            os.rm("~/.local/bin/xmake")
        end
    end
end

-- do install
function _install(sourcedir)

    -- the install task
    local install_task = function ()

        -- get the install directory
        local installdir = is_host("windows") and os.programdir() or "~/.local/bin"

        -- trace
        tty.erase_line_to_start().cr()
        cprintf("${yellow}  => ${clear}installing to %s .. ", installdir)
        local ok = try
        {
            function ()

                -- install it
                os.cd(sourcedir)
                if is_host("windows") then
                    if os.isfile(win_installer_name) then
                        -- /D sets the default installation directory ($INSTDIR), overriding InstallDir and InstallDirRegKey. It must be the last parameter used in the command line and must not contain any quotes, even if the path contains spaces. Only absolute paths are supported.
                        local params = ("/D=" .. os.programdir()):split("%s", { strict = true })
                        local testfile = path.join(os.programdir(), "temp-install")
                        local no_admin = os.trycp(path.join(os.programdir(), "scripts", "run.vbs"), testfile)
                        os.tryrm(testfile)
                        if no_admin then table.insert(params, 1, "/NOADMIN") end
                        -- need UAC?
                        if winos:version():gt("winxp") then
                            _run_win_v(win_installer_name, params, not no_admin)
                        else
                            _run_win_v(win_installer_name, params, false)
                        end
                    else
                        raise("the installer(%s) not found!", win_installer_name)
                    end
                else
                    os.vrun("make build")
                    process.openv("./scripts/get.sh", {"__local__", "__install_only__"}, {stdout = os.tmpfile(), stderr = os.tmpfile()}, {detach = true}):close()
                end
                return true
            end,
            catch
            {
                function (errors)
                    vprint(errors)
                end
            }
        }

        -- trace
        if ok then
            tty.erase_line_to_start().cr()
            cprint("${yellow}  => ${clear}install to %s .. ${color.success}${text.success}", installdir)
        else
            raise("install failed!")
        end
    end

    -- do install
    if option.get("verbose") then
        install_task()
    else
        runjobs("update/install", install_task, {progress = true})
    end
end

-- do install script
function _install_script(sourcedir)

    -- trace
    cprintf("\r${yellow}  => ${clear}install script to %s .. ", os.programdir())

    local source = path.join(sourcedir, "xmake")
    local dirname = path.filename(os.programdir())
    if dirname ~= "xmake" then
        local target = path.join(sourcedir, dirname)
        os.mv(source, target)
        source = target
    end

    local ok = try
    {
        function ()
            if is_host("windows") then
                local script_original = path.join(os.programdir(), "scripts", "update-script.bat")
                local script = os.tmpfile() .. ".bat"
                os.cp(script_original, script)
                local params = { "/c", script, os.programdir(),  source }
                os.tryrm(script_original .. ".bak")
                local access = os.trymv(script_original, script_original .. ".bak")
                _run_win_v("cmd", params, not access)
                return true
            else
                local script = path.join(os.programdir(), "scripts", "update-script.sh")
                return _sudo_v("sh", { script, os.programdir(), source })
            end
        end,
        catch
        {
            function (errors)
                vprint(errors)
            end
        }
    }
    -- trace
    if ok then
        cprint("${color.success}${text.success}")
    else
        cprint("${color.failure}${text.failure}")
    end
end

function _check_repo(sourcedir)
    -- this file will exists for long time
    if not os.isfile(path.join(sourcedir, "xmake/core/_xmake_main.lua")) then
        raise("invalid xmake repo, please check your input!")
    end
end

function _check_win_installer(sourcedir)
    local file = path.join(sourcedir, win_installer_name)
    if not os.isfile(file) then
        raise("installer not found at " .. sourcedir)
    end

    local fp = io.open(file, "rb")
    local header = fp:read(math.min(1000, fp:size()))
    fp:close()
    if header:startswith("MZ") then
        return
    end
    if header:find('\0', 1, true) or not option.get("verbose") then
        raise("installer is broken")
    else
        -- may be a text file, print content for debug
        raise("installer is broken: " .. header)
    end
end

-- main
function main()

    -- only uninstall it
    if option.get("uninstall") then

        -- do uninstall
        _uninstall()

        -- trace
        cprint("${color.success}uninstall ok!")
        return
    end

    -- enter environment
    environment.enter()

    -- has been installed?
    local fetchinfo   = assert(fetch_version(option.get("xmakever")), "cannot fetch xmake version info!")
    local is_official = fetchinfo.is_official
    local mainurls    = fetchinfo.urls
    local version     = fetchinfo.version
    if is_official and xmake.version():eq(version) and not option.get("force") then
        cprint("${bright}xmake %s has been installed!", version)
        return
    end

    -- get urls on windows
    local script_only = option.get("scriptonly")
    if is_host("windows") and not script_only then
        if not is_official then
            raise("not support to update from unofficial source on windows, missing '--scriptonly' flag?")
        end

        if version:find('.', 1, true) then
            local winarch = os.arch() == "x64" and "win64" or "win32"
            mainurls = {format("https://ci.appveyor.com/api/projects/waruqi/xmake/artifacts/xmake-installer.exe?tag=%s&pr=false&job=Image%%3A+Visual+Studio+2017%%3B+Platform%%3A+%s", version, os.arch()),
                        format("https://github.com/xmake-io/xmake/releases/download/%s/xmake-%s.%s.exe", version, version, winarch),
                        format("https://cdn.jsdelivr.net/gh/xmake-mirror/xmake-releases@%s/xmake-%s.%s.exe.zip", version, version, winarch),
                        format("https://gitlab.com/xmake-mirror/xmake-releases/raw/%s/xmake-%s.%s.exe.zip", version, version, winarch)}
        else
            -- regard as a git branch, fetch from ci
            mainurls = {format("https://ci.appveyor.com/api/projects/waruqi/xmake/artifacts/xmake-installer.exe?branch=%s&pr=false&job=Image%%3A+Visual+Studio+2017%%3B+Platform%%3A+%s", version, os.arch())}
        end

        -- re-sort mainurls
        fasturl.add(mainurls)
        mainurls = fasturl.sort(mainurls)
    end

    -- trace
    if is_official then
        cprint("update version ${green}%s${clear} from official source ..", version)
    else
        cprint("update version ${green}%s${clear} from ${underline}%s${clear} ..", version, mainurls[1])
    end

    -- get the temporary source directory without ramdisk (maybe too large)
    local sourcedir = path.join(os.tmpdir({ramdisk = false}), "xmakesrc", version)
    vprint("prepared to download to temp dir %s ..", sourcedir)

    -- all user provided urls are considered as git url since check has been performed in fetch_version
    local install_from_git = not is_official or git.checkurl(mainurls[1])

    -- the download task
    local download_task = function ()
        for idx, url in ipairs(mainurls) do
            tty.erase_line_to_start().cr()
            cprintf("${yellow}  => ${clear}downloading %s .. ", url)
            local ok = try
            {
                function ()
                    os.tryrm(sourcedir)
                    if not install_from_git then
                        os.mkdir(sourcedir)
                        local installerfile = path.join(sourcedir, win_installer_name)
                        if url:endswith(".zip") then
                            http.download(url, installerfile .. ".zip")
                            archive.extract(installerfile .. ".zip", installerfile .. ".dir")
                            local file = find_file("*.exe", installerfile .. ".dir")
                            if file then
                                os.cp(file, installerfile)
                            end
                        else
                            http.download(url, installerfile)
                        end
                    else
                        git.clone(url, {depth = 1, recurse_submodules = not script_only, branch = version, outputdir = sourcedir})
                    end
                    return true
                end,
                catch
                {
                    function (errors)
                        vprint(errors)
                    end
                }
            }
            tty.erase_line_to_start().cr()
            if ok then
                cprint("${yellow}  => ${clear}download %s .. ${color.success}${text.success}", url)
                break
            else
                cprint("${yellow}  => ${clear}download %s .. ${color.failure}${text.failure}", url)
            end
            if not ok and idx == #mainurls then
                raise("download failed!")
            end
        end
    end

    -- do download
    if option.get("verbose") then
        download_task()
    else
        runjobs("update/download", download_task, {progress = true})
    end

    -- leave environment
    environment.leave()

    if install_from_git then
        _check_repo(sourcedir)
    else
        _check_win_installer(sourcedir)
    end

    -- do install
    if script_only then
        _install_script(sourcedir)
    else
        _install(sourcedir)
    end
end

