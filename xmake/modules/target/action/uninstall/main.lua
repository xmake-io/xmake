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
-- @file        main.lua
--

-- uninstall files
function _uninstall_files(target)
    local _, dstfiles = target:installfiles()
    for _, dstfile in ipairs(dstfiles) do
        os.vrm(dstfile)
    end
end

-- the builtin uninstall main entry
function main(target, opt)

    -- get install directory
    local installdir = target:installdir()
    if not installdir then
        return
    end

    -- trace
    print("uninstalling %s from %s ..", target:name(), installdir)

    -- call script
    if not target:is_phony() then
        local install_style = target:is_plat("windows", "mingw") and "windows" or "unix"
        local script = import(install_style, {anonymous = true})["uninstall_" .. target:kind()]
        if script then
            script(target, opt)
        end
    end

    -- uninstall the other files
    _uninstall_files(target)
end

