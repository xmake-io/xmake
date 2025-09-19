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
import("core.base.semver")
import("core.base.hashset")
import("lib.detect.find_tool")
import("lib.detect.find_file")
import("utils.archive")
import("detect.sdks.find_qt")
import(".batchcmds")

-- get the debuild
function _get_debuild()
    local debuild = find_tool("debuild", {force = true})
    assert(debuild, "debuild not found, please run `sudo apt install devscripts` to install it!")
    return debuild
end

-- get chrpath tool for removing RPATH
function _get_chrpath()
    local chrpath = find_tool("chrpath", {force = false})
    return chrpath
end

-- get archive file
function _get_archivefile(package)
    return path.absolute(path.join(path.directory(package:sourcedir()), package:name() .. "_" .. package:version() .. ".orig.tar.gz"))
end

-- detect if this is a Qt project
function _is_qt_project(package)
    -- Method 1: Check for Qt libraries in links
    local links = package:get("links")
    if links then
        for _, link in ipairs(links) do
            if link:lower():find("qt") then
                print("Qt project detected via link:", link)
                return true
            end
        end
    end

    -- Method 2: Check executable for Qt dependencies using ldd
    local main_executable = nil
    
    -- Try to find the main executable path
    local install_rootdir = package:install_rootdir()
    if install_rootdir then
        local bin_dir = path.join(install_rootdir, "bin")
        if os.isdir(bin_dir) then
            local exe_path = path.join(bin_dir, package:name())
            if os.isfile(exe_path) then
                main_executable = exe_path
            end
        end
    end
    
    -- If we couldn't find it in install dir, check if it exists in build output
    if not main_executable then
        local outputfile = package:outputfile()
        if outputfile and os.isfile(outputfile) then
            main_executable = outputfile
        end
    end
    
    if main_executable and os.isfile(main_executable) then
        local ldd_output = os.iorunv("ldd", {main_executable})
        if ldd_output then
            -- Check for Qt libraries in ldd output
            if ldd_output:lower():find("libqt") or 
               ldd_output:lower():find("qt5") or 
               ldd_output:lower():find("qt6") then
                return true
            end
        end
    end

    -- Method 3: Check source files for Qt headers/includes
    local srcfiles, _ = package:sourcefiles()
    for _, srcfile in ipairs(srcfiles or {}) do
        if srcfile:endswith(".cpp") or srcfile:endswith(".cc") or srcfile:endswith(".cxx") then
            if os.isfile(srcfile) then
                local content = io.readfile(srcfile)
                if content and (content:find("#include.*[Qq][Tt]") or 
                               content:find("#include.*<Q") or
                               content:find("QApplication") or
                               content:find("QWidget") or
                               content:find("QMainWindow")) then
                    return true
                end
            end
        end
    end
    return false
end

-- get Qt version and generate appropriate dependency strings
function _get_qt_dependencies(package)
    local qt = find_qt()
    local qt_deps = {}
    local qt_build_deps = {}
    if not qt then
        -- Fallback generic dependencies
        table.insert(qt_deps, "libqt5core5a")
        table.insert(qt_deps, "libqt5gui5")
        table.insert(qt_build_deps, "qtbase5-dev")
        return qt_deps, qt_build_deps
    end
    local qt_version = qt.sdkver or "5.15.3"
    local qt_major = qt_version:match("^(%d+)")
    if qt_major == "6" then
        -- Qt6 dependencies
        table.insert(qt_deps, "libqt6core6")
        table.insert(qt_deps, "libqt6gui6")
        table.insert(qt_deps, "libqt6widgets6")
        
        -- Qt6 build dependencies
        table.insert(qt_build_deps, "qt6-base-dev")
        table.insert(qt_build_deps, "qt6-tools-dev")
        table.insert(qt_build_deps, "qt6-tools-dev-tools")
        -- Check for additional Qt6 modules based on links
        local links = package:get("links") or {}
        for _, link in ipairs(links) do
            local lower_link = link:lower()
            if lower_link:find("qt6network") or lower_link:find("qtnetwork") then
                table.insert(qt_deps, "libqt6network6")
            elseif lower_link:find("qt6sql") or lower_link:find("qtsql") then
                table.insert(qt_deps, "libqt6sql6")
            elseif lower_link:find("qt6xml") or lower_link:find("qtxml") then
                table.insert(qt_deps, "libqt6xml6")
            elseif lower_link:find("qt6opengl") or lower_link:find("qtopengl") then
                table.insert(qt_deps, "libqt6opengl6")
                table.insert(qt_build_deps, "qt6-opengl-dev")
            elseif lower_link:find("qt6multimedia") or lower_link:find("qtmultimedia") then
                table.insert(qt_deps, "libqt6multimedia6")
                table.insert(qt_build_deps, "qt6-multimedia-dev")
            elseif lower_link:find("qt6webengine") or lower_link:find("qtwebengine") then
                table.insert(qt_deps, "libqt6webenginewidgets6")
                table.insert(qt_build_deps, "qt6-webengine-dev")
            elseif lower_link:find("qt6qml") or lower_link:find("qtqml") then
                table.insert(qt_deps, "libqt6qml6")
                table.insert(qt_build_deps, "qt6-declarative-dev")
            end
        end
        
    else
        -- Qt5 dependencies (default)
        table.insert(qt_deps, "libqt5core5a")
        table.insert(qt_deps, "libqt5gui5")
        table.insert(qt_deps, "libqt5widgets5")
        
        -- Qt5 build dependencies
        table.insert(qt_build_deps, "qtbase5-dev")
        table.insert(qt_build_deps, "qt5-qmake")
        table.insert(qt_build_deps, "qttools5-dev")
        table.insert(qt_build_deps, "qttools5-dev-tools")
        
        -- Check for additional Qt5 modules based on links
        local links = package:get("links") or {}
        for _, link in ipairs(links) do
            local lower_link = link:lower()
            if lower_link:find("qt5network") or lower_link:find("qtnetwork") then
                table.insert(qt_deps, "libqt5network5")
            elseif lower_link:find("qt5sql") or lower_link:find("qtsql") then
                table.insert(qt_deps, "libqt5sql5")
            elseif lower_link:find("qt5xml") or lower_link:find("qtxml") then
                table.insert(qt_deps, "libqt5xml5")
            elseif lower_link:find("qt5opengl") or lower_link:find("qtopengl") then
                table.insert(qt_deps, "libqt5opengl5")
                table.insert(qt_build_deps, "libqt5opengl5-dev")
            elseif lower_link:find("qt5multimedia") or lower_link:find("qtmultimedia") then
                table.insert(qt_deps, "libqt5multimedia5")
                table.insert(qt_build_deps, "qtmultimedia5-dev")
            elseif lower_link:find("qt5webengine") or lower_link:find("qtwebengine") then
                table.insert(qt_deps, "libqt5webenginewidgets5")
                table.insert(qt_build_deps, "qtwebengine5-dev")
            elseif lower_link:find("qt5qml") or lower_link:find("qtqml") then
                table.insert(qt_deps, "libqt5qml5")
                table.insert(qt_build_deps, "qtdeclarative5-dev")
            elseif lower_link:find("qt5svg") or lower_link:find("qtsvg") then
                table.insert(qt_deps, "libqt5svg5")
                table.insert(qt_build_deps, "libqt5svg5-dev")
            end
        end
    end
    return qt_deps, qt_build_deps
end

-- remove RPATH from binaries
function _remove_rpath_from_binaries(package)
    local chrpath = _get_chrpath()
    if not chrpath then
        return {}
    end
    
    local rpath_cmds = {}
    local install_rootdir = package:install_rootdir()
    if install_rootdir then
        -- Find all binaries and shared libraries
        local binaries = os.files(path.join(install_rootdir, "**"))
        for _, binary in ipairs(binaries) do
            if os.isfile(binary) then
                -- Check if it's a binary or shared library
                local file_output = os.iorunv("file", {binary})
                if file_output and (file_output:find("ELF.*executable") or file_output:find("ELF.*shared object")) then
                    -- Check if it has RPATH/RUNPATH
                    local chrpath_output = os.iorunv(chrpath.program, {"-l", binary})
                    if chrpath_output and (chrpath_output:find("RPATH=") or chrpath_output:find("RUNPATH=")) then
                        local rel_path = _translate_filepath(package, binary)
                        table.insert(rpath_cmds, string.format("chrpath -d \"%s\" || true", rel_path))
                    end
                end
            end
        end
    end
    return rpath_cmds
end

-- translate the file path
function _translate_filepath(package, filepath)
    return filepath:replace(package:install_rootdir(), "$(PREFIX)", {plain = true})
end

-- get install command
function _get_customcmd(package, installcmds, cmd)
    local opt = cmd.opt or {}
    local kind = cmd.kind
    if kind == "cp" then
        local srcfiles = os.files(cmd.srcpath)
        for _, srcfile in ipairs(srcfiles) do
            -- the destination is directory? append the filename
            local dstfile = _translate_filepath(package, cmd.dstpath)
            if #srcfiles > 1 or path.islastsep(dstfile) then
                if opt.rootdir then
                    dstfile = path.join(dstfile, path.relative(srcfile, opt.rootdir))
                else
                    dstfile = path.join(dstfile, path.filename(srcfile))
                end
            end
            table.insert(installcmds, string.format("install -Dpm0644 \"%s\" \"%s\"", srcfile, dstfile))
        end
    elseif kind == "rm" then
        local filepath = _translate_filepath(package, cmd.filepath)
        table.insert(installcmds, string.format("rm -f \"%s\"", filepath))
    elseif kind == "rmdir" then
        local dir = _translate_filepath(package, cmd.dir)
        table.insert(installcmds, string.format("rm -rf \"%s\"", dir))
    elseif kind == "mv" then
        local srcpath = _translate_filepath(package, cmd.srcpath)
        local dstpath = _translate_filepath(package, cmd.dstpath)
        table.insert(installcmds, string.format("mv \"%s\" \"%s\"", srcfile, dstfile))
    elseif kind == "cd" then
        local dir = _translate_filepath(package, cmd.dir)
        table.insert(installcmds, string.format("cd \"%s\"", dir))
    elseif kind == "mkdir" then
        local dir = _translate_filepath(package, cmd.dir)
        table.insert(installcmds, string.format("mkdir -p \"%s\"", dir))
    elseif cmd.program then
        local argv = {}
        for _, arg in ipairs(cmd.argv) do
            if path.instance_of(arg) then
                arg = arg:clone():set(_translate_filepath(package, arg:rawstr())):str()
            elseif path.is_absolute(arg) then
                arg = _translate_filepath(package, arg)
            end
            table.insert(argv, arg)
        end
        table.insert(installcmds, string.format("%s", os.args(table.join(cmd.program, argv))))
    end
end

-- get build commands
function _get_buildcmds(package, buildcmds, cmds)
    for _, cmd in ipairs(cmds) do
        _get_customcmd(package, buildcmds, cmd)
    end
end

-- get install commands
function _get_installcmds(package, installcmds, cmds)
    for _, cmd in ipairs(cmds) do
        _get_customcmd(package, installcmds, cmd)
    end
    
    -- Add RPATH removal commands
    local rpath_cmds = _remove_rpath_from_binaries(package)
    for _, rpath_cmd in ipairs(rpath_cmds) do
        table.insert(installcmds, rpath_cmd)
    end
end

-- get uninstall commands
function _get_uninstallcmds(package, uninstallcmds, cmds)
    for _, cmd in ipairs(cmds) do
        _get_customcmd(package, uninstallcmds, cmd)
    end
end

-- validate maintainer format
function _validate_maintainer(maintainer)
    if not maintainer or maintainer == "" then
        return "Unknown <unknown@example.com>"
    end
    
    -- Check if it already has proper format (Name <email>)
    if maintainer:match("^.+%s+<.+@.+>$") then
        return maintainer
    end
    
    -- If it's just a name, add a default email
    if not maintainer:find("@") then
        return maintainer .. " <" .. maintainer:lower():gsub("%s+", ".") .. "@example.com>"
    end
    
    -- If it's just an email, add a name
    if maintainer:find("@") and not maintainer:find("<") then
        local name = maintainer:gsub("@.*", ""):gsub("[%.%_%-]", " ")
        return name .. " <" .. maintainer .. ">"
    end
    
    return maintainer
end

-- get specvars
function _get_specvars(package)
    local is_qt = _is_qt_project(package)
    local specvars = table.clone(package:specvars())
    local datestr = os.iorunv("date", {"-u", "+%a, %d %b %Y %H:%M:%S +0000"}, {envs = {LC_TIME = "en_US"}})
    if datestr then
        datestr = datestr:trim()
    end
    specvars.PACKAGE_DATE = datestr or ""
    
    -- Validate and fix maintainer format
    local author = package:get("author") or "unknown"
    local maintainer = package:get("maintainer") or author
    specvars.PACKAGE_MAINTAINER = _validate_maintainer(maintainer)
    specvars.PACKAGE_COPYRIGHT = os.date("%Y") .. " " .. author
    specvars.PACKAGE_INSTALLCMDS = function ()
        local prefixdir = package:get("prefixdir")
        package:set("prefixdir", nil)
        local installcmds = {}
        _get_installcmds(package, installcmds, batchcmds.get_installcmds(package):cmds())
        for _, component in table.orderpairs(package:components()) do
            if component:get("default") ~= false then
                _get_installcmds(package, installcmds, batchcmds.get_installcmds(component):cmds())
            end
        end
        package:set("prefixdir", prefixdir)
        return table.concat(installcmds, "\n\t")
    end
    specvars.PACKAGE_UNINSTALLCMDS = function ()
        local uninstallcmds = {}
        _get_uninstallcmds(package, uninstallcmds, batchcmds.get_uninstallcmds(package):cmds())
        for _, component in table.orderpairs(package:components()) do
            if component:get("default") ~= false then
                _get_uninstallcmds(package, uninstallcmds, batchcmds.get_uninstallcmds(component):cmds())
            end
        end
        return table.concat(uninstallcmds, "\n\t")
    end
    specvars.PACKAGE_BUILDCMDS = function ()
        local buildcmds = {}
        _get_buildcmds(package, buildcmds, batchcmds.get_buildcmds(package):cmds())
        return table.concat(buildcmds, "\n\t")
    end
    specvars.PACKAGE_BUILDREQUIRES = function ()
        local requires = {}
        local buildrequires = package:get("buildrequires")
        if buildrequires then
            for _, buildrequire in ipairs(buildrequires) do
                table.insert(requires, buildrequire)
            end
        else
            local programs = hashset.new()
            for _, cmd in ipairs(batchcmds.get_buildcmds(package):cmds()) do
                local program = cmd.program
                if program then
                    programs:insert(program)
                end
            end
            local map = {
                xmake = "xmake",
                cmake = "cmake",
                make = "make"
            }
            for _, program in programs:keys() do
                local requirename = map[program]
                if requirename then
                    table.insert(requires, requirename)
                end
            end
        end
        
        -- Add chrpath for RPATH removal
        table.insert(requires, "chrpath")
        
        -- Add Qt build dependencies if this is a Qt project
        if is_qt then
            local _, qt_build_deps = _get_qt_dependencies(package)
            for _, qt_dep in ipairs(qt_build_deps) do
                table.insert(requires, qt_dep)
            end
        end
        
        return table.concat(requires, ", ")
    end
    
    -- Add Qt runtime dependencies to package dependencies
    specvars.PACKAGE_QT_DEPENDS = function ()
        if is_qt then
            local qt_deps, _ = _get_qt_dependencies(package)
            if #qt_deps > 0 then
                return ", " .. table.concat(qt_deps, ", ")
            end
        end
        return ""
    end
    
    return specvars
end

-- pack deb package
function _pack_deb(debuild, package)

    -- install the initial debian directory
    local sourcedir = package:sourcedir()
    local debiandir = path.join(sourcedir, "debian")
    if not os.isdir(debiandir) then
        local debiandir_template = package:get("specfile") or path.join(os.programdir(), "scripts", "xpack", "deb", "debian")
        os.cp(debiandir_template, debiandir, {writeable = true})
    end

    -- replace variables in specfile
    -- and we need to avoid `attempt to yield across a C-call boundary` in io.gsub
    local specvars = _get_specvars(package)
    local pattern = package:extraconf("specfile", "pattern") or "%${([^\n]-)}"
    local specvars_names = {}
    local specvars_values = {}
    for _, specfile in ipairs(os.files(path.join(debiandir, "**"))) do
        io.gsub(specfile, "(" .. pattern .. ")", function(_, name)
            table.insert(specvars_names, name)
        end)
    end
    for _, name in ipairs(specvars_names) do
        name = name:trim()
        if specvars_values[name] == nil then
            local value = specvars[name]
            if type(value) == "function" then
                value = value()
            end
            if value ~= nil then
                dprint("[%s]:  > replace %s -> %s", path.filename(specfile), name, value)
            end
            if type(value) == "table" then
                dprint("invalid variable value", value)
            end
            specvars_values[name] = value
        end
    end
    for _, specfile in ipairs(os.files(path.join(debiandir, "**"))) do
        io.gsub(specfile, "(" .. pattern .. ")", function(_, name)
            name = name:trim()
            return specvars_values[name]
        end)
    end

    -- archive source files
    local srcfiles, dstfiles = package:sourcefiles()
    for idx, srcfile in ipairs(srcfiles) do
        os.vcp(srcfile, dstfiles[idx])
    end
    for _, component in table.orderpairs(package:components()) do
        if component:get("default") ~= false then
            local srcfiles, dstfiles = component:sourcefiles()
            for idx, srcfile in ipairs(srcfiles) do
                os.vcp(srcfile, dstfiles[idx])
            end
        end
    end

    -- archive install files
    local rootdir = package:source_rootdir()
    local oldir = os.cd(rootdir)
    local archivefiles = os.files("**")
    os.cd(oldir)
    local archivefile = _get_archivefile(package)
    os.tryrm(archivefile)
    archive.archive(archivefile, archivefiles, {curdir = rootdir, compress = "best"})

    -- build package
    os.vrunv(debuild, {"-us", "-uc"}, {curdir = sourcedir})

    -- copy deb file
    os.vcp(path.join(path.directory(sourcedir), "*.deb"), package:outputfile())
end

function main(package)
    if not is_host("linux") then
        return
    end

    cprint("packing %s", package:outputfile())

    -- get debuild
    local debuild = _get_debuild()

    -- pack deb package
    _pack_deb(debuild.program, package)
end