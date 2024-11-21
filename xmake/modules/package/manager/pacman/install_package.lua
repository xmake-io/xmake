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
-- @param opt   the options, e.g. {verbose = true, pacman = "the package name"}
--
-- @return      true or false
--
function main(name, opt)

    -- get configs
    opt = opt or {}
    local configs = opt.configs or {}

    -- find pacman
    local pacman = find_tool("pacman")
    if not pacman then
        raise("pacman not found!")
    end

    -- for msys2/mingw? mingw-w64-[i686|x86_64]-xxx
    if is_subhost("msys") then
        local msystem = configs.msystem
        if not msystem and opt.plat == "mingw" then
            msystem = "mingw"
        end
        if msystem == "mingw" then
            -- try to get the package prefix from the environment first
            -- https://www.msys2.org/docs/package-naming/
            local prefix = "mingw-w64-"
            local arch = (opt.arch == "x86_64" and "x86_64-" or "i686-")
            local msystem_env = os.getenv("MSYSTEM")
            if msystem_env and not msystem_env:startswith("MINGW") then
                local i, j = msystem_env:find("%D+")
                name = prefix .. msystem_env:sub(i, j):lower() .. "-" .. arch .. name
            else
                name = prefix .. arch .. name
            end
        else
            -- TODO other msystem, e.g. clang, msys, ucrt, ...
        end
    end

    -- init argv
    local argv = {"-Sy", "--noconfirm", "--needed", "--disable-download-timeout", name}
    if opt.verbose or option.get("verbose") then
        table.insert(argv, "--verbose")
    end

    -- install package directly if the current user is root
    if is_host("windows") or os.isroot() then
        os.vrunv(pacman.program, argv)
    -- install with administrator permission?
    elseif sudo.has() then

        -- install it if be confirmed
        local description = format("try installing %s with administrator permission", name)
        local confirm = utils.confirm({default = true, description = description})
        if confirm then
            sudo.vrunv(pacman.program, argv)
        end
    else
        raise("cannot get administrator permission!")
    end
end
