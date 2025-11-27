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
-- @file        windeployqt.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.tool.toolchain")
import("lib.detect.find_file")
import("lib.detect.find_path")
import("detect.sdks.find_qt")

-- prepare windeployqt arguments and environment
function prepare(target, bindir, installfiles)
    -- get qt sdk
    local qt = find_qt()
    if not qt then
        return nil, nil, nil
    end

    -- get windeployqt
    local search_dirs = {}
    if qt.bindir_host then table.insert(search_dirs, qt.bindir_host) end
    if qt.bindir then table.insert(search_dirs, qt.bindir) end
    local program = find_file("windeployqt" .. (is_host("windows") and ".exe" or ""), search_dirs)
    if not program or not os.isexec(program) then
        return nil, nil, nil
    end

    -- find qml directory
    local qmldir = target:values("qt.deploy.qmldir")
    if not qmldir then
        for _, sourcebatch in pairs(target:sourcebatches()) do
            if sourcebatch.rulename == "qt.qrc" then
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    qmldir = find_path("*.qml", path.directory(sourcefile))
                    if qmldir then
                        break
                    end
                end
            end
        end
    else
        qmldir = path.join(target:scriptdir(), qmldir)
    end

    -- prepare environment
    local envs = nil
    if target:is_plat("windows") then
        -- find msvc to set VCINSTALLDIR env
        local msvc = toolchain.load("msvc", {plat = target:plat(), arch = target:arch()})
        if msvc then
            local vcvars = msvc:config("vcvars")
            if vcvars and vcvars.VCInstallDir then
                envs = {VCINSTALLDIR = vcvars.VCInstallDir}
            end
        end
    elseif target:is_plat("mingw") then
        -- add mingw dlls to PATH
        local mingw = toolchain.load("mingw", {plat = target:plat(), arch = target:arch()})
        if mingw then
            local mingw_bindir = mingw:bindir()
            if mingw_bindir then
                envs = {PATH = {}}
                table.insert(envs.PATH, mingw_bindir)
            end
        end
    end

    -- bind qt bin path
    -- https://github.com/xmake-io/xmake/issues/4297
    if qt.bindir_host or qt.bindir then
        envs = envs or {}
        envs.PATH = envs.PATH or {}
        if type(envs.PATH) == "string" then
            envs.PATH = {envs.PATH}
        end
        if qt.bindir_host then
            table.insert(envs.PATH, qt.bindir_host)
        end
        if qt.bindir then
            table.insert(envs.PATH, qt.bindir)
        end
        local curpath = os.getenv("PATH")
        if curpath then
            table.join2(envs.PATH, path.splitenv(curpath))
        end
    end

    -- prepare arguments
    local argv = {"--force"}
    if option.get("diagnosis") then
        table.insert(argv, "--verbose=2")
    elseif option.get("verbose") then
        table.insert(argv, "--verbose=1")
    else
        table.insert(argv, "--verbose=0")
    end

    -- make sure user flags have priority over default
    local user_flags = table.wrap(target:values("qt.deploy.flags"))
    if table.contains(user_flags, "--debug", "--release") then
        if is_mode("debug") then
            table.insert(argv, "--debug")
        else
            table.insert(argv, "--release")
        end
    end

    if qmldir then
        table.insert(argv, "--qmldir=" .. qmldir)
    end

    -- add user flags
    if user_flags then
        argv = table.join(argv, user_flags)
    end

    -- windeployqt for both target and its deps
    table.join2(argv, installfiles)

    return program, argv, envs
end

