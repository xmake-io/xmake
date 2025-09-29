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
-- @author      Shiffted
-- @file        versionfiles.lua
--

import(".api_checker")

function main(opt)
    opt = opt or {}
    api_checker.check_packages("versionfiles", table.join(opt, {check = function(package, value)
        local versionfile_path = value
        if not path.is_absolute(versionfile_path) then
            local subpath = versionfile_path
            versionfile_path = path.join(package:scriptdir(), subpath)
            if not os.isfile(versionfile_path) and package:base() then
                versionfile_path = path.join(package:base():scriptdir(), subpath)
            end
        end
        if not os.isfile(versionfile_path) then
            return false, string.format("versionfile '%s' not found", value)
        end
        return true
    end}))
end
