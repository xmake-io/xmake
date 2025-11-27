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
-- @file        windows.lua
--

-- imports
import("rules.qt.install.windeployqt", {rootdir = os.programdir()})

-- get bin directory, if set_prefixdir changed bindir, we should use bindir
function _get_bindir(target)
    local bindir = assert(target:bindir(), "please use `xmake install -o installdir` or `set_installdir` to set install directory on windows.")
    return bindir
end

-- install application package for windows
function main(target, opt)

    local bindir = _get_bindir(target)
    local targetfile = path.join(bindir, path.filename(target:targetfile()))
    local installfiles = {}
    table.insert(installfiles, targetfile)
    for _, dep in ipairs(target:orderdeps()) do
        if dep:rule("qt.shared") then -- qt.shared deps
            local installfile = path.join(bindir, path.filename(dep:targetfile()))
            table.insert(installfiles, installfile)
        end
    end

    -- prepare windeployqt arguments
    local program, argv, envs = windeployqt.prepare(target, bindir, installfiles)
    assert(program, "windeployqt.exe not found!")

    -- deploy Qt dependencies
    os.vrunv(program, argv, {envs = envs})
end
