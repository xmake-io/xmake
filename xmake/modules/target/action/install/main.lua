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

-- install files
function _install_files(target)

    local srcfiles, dstfiles = target:installfiles()
    if srcfiles and dstfiles then
        local i = 1
        for _, srcfile in ipairs(srcfiles) do
            local dstfile = dstfiles[i]
            if dstfile then
                os.vcp(srcfile, dstfile)
            end
            i = i + 1
        end
    end
end

-- the builtin install main entry
function main(target, opt)

    -- get install directory
    local installdir = target:installdir()
    if not installdir then
        return
    end

    -- trace
    print("installing to %s ..", installdir)

    -- call script
    if not target:isphony() then
        local install_style = target:is_plat("windows", "mingw") and "windows" or "unix"
        local script = import(install_style, {anonymous = true})["install_" .. target:targetkind()]
        if script then
            script(target, opt)
        end
    end

    -- install other files
    _install_files(target)
end
