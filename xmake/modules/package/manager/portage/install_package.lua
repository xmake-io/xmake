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
-- @file        install_package.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")
import("privilege.sudo")

-- install package
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, emerge = "the package name"}
--
-- @return      true or false
--
function main(name, opt)

    -- init options
    opt = opt or {}

    -- find emerge
    local emerge = find_tool("emerge")
    if not emerge then
        raise("emerge not found!")
    end

    -- for msys2/mingw? mingw-w64-[i686|x86_64]-xxx
    if opt.plat == "mingw" then
        name = "mingw64-runtime"
    end

    -- init argv
    -- ask for confirmation, view tree of packages, verbose
    -- it is set this way because Portage compiles from source
    -- therefore it's better to have more info and ask for confirmation
    -- that way the user can ensure they installed the package with the correct USE flags
    local argv = {"-a", "-t", "-v", opt.emerge or name}
    if opt.verbose or option.get("verbose") then
        table.insert(argv, "-v")
    end

    -- install package directly if the current user is root
    if is_subhost("msys") or os.isroot() then
        os.vrunv(emerge.program, argv)
    -- install with administrator permission?
    elseif sudo.has() then

        -- install it if be confirmed
        local description = format("try installing %s with administrator permission", name)
        local confirm = utils.confirm({default = true, description = description})
        if confirm then
            sudo.vrunv(emerge.program, argv)
        end
    else
        raise("cannot get administrator permission!")
    end
end
