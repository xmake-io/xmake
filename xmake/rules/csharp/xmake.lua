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
-- @author      JassJam
-- @file        xmake.lua
--

rule("csharp.build")
    set_extensions(".cs", ".csproj")
    set_sourcekinds("cs", "csproj", {objectfiles = false})

    local function _find_csproj(target)
        local csproj = target:data("csharp.csproj")
        if csproj then
            return csproj
        end
        for _, sourcefile in ipairs(target:sourcefiles()) do
            if path.extension(sourcefile):lower() == ".csproj" then
                local csprojabs = path.is_absolute(sourcefile) and sourcefile or path.absolute(sourcefile, os.projectdir())
                if os.isfile(csprojabs) then
                    return csprojabs
                end
            end
        end
        return nil
    end

    local function _build_mode_to_configuration()
        local mode
        if type(get_config) == "function" then
            mode = get_config("mode")
        end
        if not mode and type(is_mode) == "function" then
            if is_mode("debug") then
                mode = "debug"
            elseif is_mode("release") then
                mode = "release"
            end
        end
        mode = mode or "release"
        local mode_lower = mode:lower()
        if mode_lower == "debug" then
            return "Debug"
        elseif mode_lower == "release" then
            return "Release"
        end
        return mode:sub(1, 1):upper() .. mode:sub(2)
    end

    local function _map_rid_arch(arch)
        arch = (arch or ""):lower()
        if arch == "x64" or arch == "x86_64" or arch == "amd64" then
            return "x64"
        elseif arch == "x86" or arch == "i386" then
            return "x86"
        elseif arch == "arm64" then
            return "arm64"
        elseif arch == "arm" or arch == "armv7" then
            return "arm"
        elseif arch == "riscv64" then
            return "riscv64"
        end
        return nil
    end

    local function _get_runtime_identifier(target)
        local rid = target:values("csharp.runtime_identifier")
        if type(rid) == "table" then
            rid = rid[1]
        end
        if rid and #rid > 0 then
            return rid
        end
        local arch = _map_rid_arch(target:arch())
        if not arch then
            return nil
        end
        local plat = target:plat()
        if plat == "windows" or plat == "mingw" or plat == "msys" or plat == "cygwin" then
            return "win-" .. arch
        elseif plat == "linux" then
            return "linux-" .. arch
        elseif plat == "macosx" then
            return "osx-" .. arch
        end
        return nil
    end

    on_load(function (target)
        local targetdir = target:targetdir()

        if targetdir and path.filename(targetdir) ~= target:name() then
            target:set("targetdir", path.join(targetdir, target:name()))
        end

        if target:is_static() or target:is_shared() then
            if not target:get("extension") then
                target:set("extension", ".dll")
            end
            if target:get("prefixname") == nil then
                target:set("prefixname", "")
            end
        end

        -- find and cache the .csproj file for later use in build/install
        local csprojfiles = {}
        for _, sourcefile in ipairs(target:sourcefiles()) do
            if path.extension(sourcefile):lower() == ".csproj" then
                table.insert(csprojfiles, sourcefile)
            end
        end
        assert(#csprojfiles > 0, "target(%s): csharp requires one .csproj in add_files()!", target:name())
        assert(#csprojfiles == 1, "target(%s): csharp only supports one .csproj file!", target:name())

        local csprojfile = csprojfiles[1]
        local csprojabs = path.is_absolute(csprojfile) and csprojfile or path.absolute(csprojfile, os.projectdir())
        assert(os.isfile(csprojabs), "target(%s): csharp .csproj not found: %s", target:name(), csprojfile)
        target:data_set("csharp.csproj", csprojabs)
    end)

    on_buildcmd(function (target, batchcmds, opt)
        local csprojfile = assert(_find_csproj(target), "target(%s): missing csharp .csproj file!", target:name())
        local configuration = _build_mode_to_configuration()
        local command = target:is_binary() and "publish" or "build"
        local argv = {
            command, csprojfile,
            "--nologo",
            "--configuration", configuration,
            "--verbosity", "minimal"
        }

        local targetdir = target:targetdir()
        local targetdirabs
        if targetdir then
            targetdirabs = path.is_absolute(targetdir) and targetdir or path.absolute(targetdir, os.projectdir())
            table.join2(argv, {"--output", targetdirabs})
        end

        local rid = _get_runtime_identifier(target)
        if rid and target:is_binary() then
            table.join2(argv, {"--runtime", rid})
        end

        batchcmds:show_progress(opt.progress, "${color.build.target}building.csharp.$(mode) %s", target:name())
        if targetdirabs then
            batchcmds:mkdir(targetdirabs)
        end

        batchcmds:vrunv("dotnet", argv, {curdir = path.directory(csprojfile)})
        batchcmds:add_depfiles(target:sourcefiles())

        local targetfile = target:targetfile()
        if targetfile then
            batchcmds:set_depmtime(os.mtime(targetfile))
            batchcmds:set_depcache(target:dependfile(targetfile))
        end
    end)

    on_clean(function (target, opt)
        local csprojfile = _find_csproj(target)
        if csprojfile then
            local csprojdir = path.directory(csprojfile)
            os.tryrm(path.join(csprojdir, "bin"))
            os.tryrm(path.join(csprojdir, "obj"))
        end
    end)

    on_install(function (target, opt)
        local function _q(arg)
            arg = tostring(arg)
            if arg:find("[%s\"]") then
                arg = "\"" .. arg:gsub("\"", "\\\"") .. "\""
            end
            return arg
        end

        local csprojfile = assert(_find_csproj(target), "target(%s): missing csharp .csproj file!", target:name())
        local configuration = _build_mode_to_configuration()

        local install_path = target:installdir()
        if target:is_binary() then
            install_path = target:installdir("bin")
        elseif target:is_static() or target:is_shared() then
            install_path = target:installdir("lib")
        end

        if not install_path or #install_path == 0 then
            return
        end

        local install_abs = path.is_absolute(install_path) and install_path or path.absolute(install_path, os.projectdir())
        os.mkdir(install_abs)

        local rid = _get_runtime_identifier(target)
        local argv = {
            "publish", csprojfile,
            "--nologo",
            "--configuration", configuration,
            "--verbosity", "minimal",
            "--output", install_abs
        }

        if rid and target:is_binary() then
            table.join2(argv, {"--runtime", rid})
        end

        local runopt = {curdir = path.directory(csprojfile)}
        if os.vrunv then
            os.vrunv("dotnet", argv, runopt)
        elseif os.runv then
            os.runv("dotnet", argv, runopt)
        elseif os.execv then
            os.execv("dotnet", argv, runopt)
        elseif os.vrun then
            os.vrun(
                "dotnet publish " .. _q(csprojfile) ..
                " --nologo --configuration " .. _q(configuration) ..
                " --verbosity minimal --output " .. _q(install_abs)
            )
        elseif os.run then
            os.run("dotnet publish " .. _q(csprojfile) ..
            " --nologo --configuration " .. _q(configuration) ..
            " --verbosity minimal --output " .. _q(install_abs)
            )
        else
            local targetdir = target:targetdir()
            if targetdir and os.isdir(targetdir) then
                os.cp(path.join(targetdir, "**"), install_abs, {rootdir = targetdir})
            end
        end

        if target:is_binary() then
            local targetdir = target:targetdir()
            if targetdir and os.isdir(targetdir) then
                os.cp(path.join(targetdir, "**"), install_abs, {rootdir = targetdir})
            end
        end
    end)

    on_installcmd(function (target, batchcmds, opt)
        local csprojfile = assert(_find_csproj(target), "target(%s): missing csharp .csproj file!", target:name())
        local configuration = _build_mode_to_configuration()

        local install_path = target:installdir()
        if target:is_binary() then
            install_path = target:installdir("bin")
        elseif target:is_static() or target:is_shared() then
            install_path = target:installdir("lib")
        end

        local install_abs
        local argv = {
            "publish", csprojfile,
            "--nologo",
            "--configuration", configuration,
            "--verbosity", "minimal"
        }
        if install_path and #install_path > 0 then
            install_abs = path.is_absolute(install_path) and install_path or path.absolute(install_path, os.projectdir())
            table.join2(argv, {"--output", install_abs})
        end

        local rid = _get_runtime_identifier(target)
        if rid and target:is_binary() then
            table.join2(argv, {"--runtime", rid})
        end

        batchcmds:show_progress(opt.progress, "${color.build.target}publishing.csharp.$(mode) %s", target:name())
        if install_abs then
            batchcmds:mkdir(install_abs)
        end

        batchcmds:vrunv("dotnet", argv, {curdir = path.directory(csprojfile)})
    end)

rule("csharp")
    add_deps("csharp.build")
