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
-- @file        xmake.lua
--

-- define platform
platform("mingw")

    -- set os
    set_os("windows")

    -- set hosts
    set_hosts("macosx", "linux", "windows")

    -- set archs
    set_archs("i386", "x86_64")

    -- set formats
    set_formats("static", "$(name).lib")
    set_formats("object", "$(name).obj")
    set_formats("shared", "$(name).dll")
    set_formats("binary", "$(name).exe")
    set_formats("symbol", "$(name).pdb")

    -- on check
    on_check(function (platform)
        import("core.project.config")
        local arch = config.get("arch")
        if not arch then
            local mingw_chost = nil
            if is_subhost("msys") then
                mingw_chost = os.getenv("MINGW_CHOST")
            end
            if mingw_chost == "i686-w64-mingw32" then
                arch = "i386"
            else
                arch = "x86_64"
            end
            config.set("arch", arch)
            cprint("checking for architecture ... ${color.success}%s", config.get("arch"))
        end
    end)

    -- set toolchains
    set_toolchains("envs", "mingw", "yasm", "nasm", "fasm", "go")

    -- set menu
    set_menu {
                config =
                {
                    {category = "MingW Configuration"                                     }
                ,   {nil, "mingw",          "kv", nil,          "The MingW SDK Directory" }
                }

            ,   global =
                {
                    {category = "MingW Configuration"                                     }
                ,   {nil, "mingw",          "kv", nil,          "The MingW SDK Directory" }
                }
            }
