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
-- @file        find_deployqt.lua
--

-- imports
import("lib.detect.find_program")

-- find deployqt
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program
--
function main(opt)

    -- init options
    opt = opt or {}
    opt.check = opt.check or function (program)
        -- check version to verify the program is working
        if is_host("windows") then
            -- windeployqt --help should return successfully
            os.run("%s --help", program)
        elseif is_host("macosx") then 
            -- macdeployqt --help should return successfully
            os.run("%s --help", program)
        else
            -- assume linux, linuxdeployqt --help should return successfully
            os.run("%s --help", program)
        end
    end

    -- define program names for different platforms
    local program_name = opt.program
    if not program_name then
        if is_host("windows") then
            program_name = "windeployqt"
        elseif is_host("macosx") then
            program_name = "macdeployqt" 
        else
            -- linux and other unix-like systems
            program_name = "linuxdeployqt"
        end
    end

    -- additional search paths for common Qt installations
    if not opt.paths then
        opt.paths = {}
        
        if is_host("windows") then
            -- common Qt installation paths on Windows
            table.insert(opt.paths, "C:\\Qt\\*\\bin")
            table.insert(opt.paths, "C:\\Qt\\Tools\\*\\bin")
            table.insert(opt.paths, path.join(os.getenv("QTDIR") or "", "bin"))
        elseif is_host("macosx") then
            -- common Qt installation paths on macOS
            table.insert(opt.paths, "/usr/local/Qt*/*/bin")
            table.insert(opt.paths, "~/Qt/*/bin") 
            table.insert(opt.paths, "/opt/Qt*/*/bin")
            table.insert(opt.paths, path.join(os.getenv("QTDIR") or "", "bin"))
        else
            -- common Qt installation paths on Linux
            table.insert(opt.paths, "/usr/lib/qt*/bin")
            table.insert(opt.paths, "/usr/lib64/qt*/bin")
            table.insert(opt.paths, "/opt/qt*/bin")
            table.insert(opt.paths, "/usr/local/qt*/bin")
            table.insert(opt.paths, "~/Qt/*/bin")
            table.insert(opt.paths, path.join(os.getenv("QTDIR") or "", "bin"))
        end
    end

    -- find program
    return find_program(program_name, opt)
end