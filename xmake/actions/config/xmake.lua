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

-- define task
task("config")

    -- set category
    set_category("action")

    -- on run
    on_run("main")

    -- set menu
    set_menu {
                -- usage
                usage = "xmake config|f [options] [target]"

                -- description
            ,   description = "Configure the project."

                -- xmake f
            ,   shortname = 'f'

                -- options
            ,   options =
                {
                    {'c', "clean",      "k",    nil     ,   "Clean the cached configure and configure all again."           }
                ,   {nil, "menu",       "k",    nil     ,   "Configure project with a menu-driven user interface."          }
                ,   {category = "."}
                ,   {'p', "plat",       "kv", "$(subhost)" , "Compile for the given platform."
                                                        ,   values = function (complete, opt)

                                                                -- imports
                                                                import("core.platform.platform")
                                                                import("core.base.hashset")

                                                                if not complete or not opt.arch then
                                                                    return platform.plats()
                                                                end

                                                                -- arch has given, find all supported platforms
                                                                local plats = {}
                                                                for _, plat in ipairs(platform.plats()) do
                                                                    local archs = hashset.from(platform.archs(plat))
                                                                    if archs:has(opt.arch) then
                                                                        table.insert(plats, plat)
                                                                    end
                                                                end
                                                                return plats
                                                            end                                                             }
                ,   {'a', "arch",       "kv", "auto"    ,   "Compile for the given architecture.",
                                                            -- show the description of all architectures
                                                            function ()

                                                                -- imports
                                                                import("core.platform.platform")

                                                                -- get all architectures
                                                                local description = {}
                                                                for i, plat in ipairs(platform.plats()) do
                                                                    local archs = platform.archs(plat)
                                                                    if archs then
                                                                        description[i] = "    - " .. plat .. ":"
                                                                        for _, arch in ipairs(archs) do
                                                                            description[i] = description[i] .. " " .. arch
                                                                        end
                                                                    end
                                                                end
                                                                return description
                                                            end
                                                        ,   values = function (complete, opt)
                                                                if not complete then return end

                                                                -- imports
                                                                import("core.platform.platform")
                                                                import("core.base.hashset")

                                                                -- get all architectures
                                                                local archset = hashset.new()
                                                                for _, plat in ipairs(opt.plat and { opt.plat } or platform.plats()) do
                                                                    local archs = platform.archs(plat)
                                                                    if archs then
                                                                        for _, arch in ipairs(archs) do
                                                                            archset:insert(arch)
                                                                        end
                                                                    end
                                                                end
                                                                return archset:to_array()
                                                            end                                                             }
                ,   {'m', "mode",       "kv", "release" ,   "Compile for the given mode."
                                                        ,   values = function (complete)

                                                                local modes = (try { function()
                                                                    return import("core.project.project").modes()
                                                                end }) or {"debug", "release"}
                                                                table.sort(modes)
                                                                if not complete then
                                                                    table.insert(modes, "... (custom)")
                                                                end
                                                                return modes
                                                            end                                                             }
                ,   {'k', "kind",       "kv", "static"  ,   "Compile for the given target kind."
                                                        ,   values = {"static", "shared", "binary"}                         }
                ,   {nil, "host",       "kv", "$(host)" ,   "The Current Host Environment."                                 }

                    -- package configuration
                ,   {category = "Package Configuration"}
                ,   {nil, "require",    "kv",   nil     ,   "Require all dependent packages?"
                                                        ,   values = function (complete)
                                                                if complete then
                                                                    return {"yes", "no"}
                                                                else
                                                                    return {"y: force to enable", "n: disable" }
                                                                end
                                                            end                                                             }
                ,   {nil, "pkg_searchdirs", "kv", nil       , "The search directories of the remote package."
                                                            , "    e.g."
                                                            , "    - xmake f --pkg_searchdirs=/dir1" .. path.envsep() .. "/dir2"}

                    -- show project menu options
                ,   function ()

                        -- import project menu
                        import("core.project.menu")

                        -- get project menu options
                        return menu.options()
                    end

                ,   {category = "Cross Complation Configuration"}
                ,   {nil, "cross",      "kv", nil,          "The Cross Toolchains Prefix"
                                                          , "e.g."
                                                          , "    - i386-mingw32-"
                                                          , "    - arm-linux-androideabi-"                                  }
                ,   {nil, "bin",        "kv", nil,          "The Cross Toolchains Bin Directory"
                                                          , "e.g."
                                                          , "    - sdk/bin (/arm-linux-gcc ..)"                             }
                ,   {nil, "sdk",        "kv", nil,          "The Cross SDK Directory"
                                                          , "e.g."
                                                          , "    - sdk/bin"
                                                          , "    - sdk/lib"
                                                          , "    - sdk/include"                                             }
                ,   {nil, "toolchain",  "kv", nil,          "The Toolchain Name"
                                                          , "e.g. "
                                                          , "    - xmake f --toolchain=clang"
                                                          , "    - xmake f --toolchain=[cross|llvm|sdcc ..] --sdk=/xxx"
                                                          , "    - run `xmake show -l toolchains` to get all toolchains"
                                                          , values = function (complete, opt)
                                                                if complete then
                                                                    import("core.tool.toolchain")
                                                                    return toolchain.list()
                                                                end
                                                            end                                                             }

                    -- show language menu options
                ,   function ()

                        -- import language menu
                        import("core.language.menu")

                        -- get config menu options
                        return menu.options("config")
                    end

                    -- show platform menu options
                ,   function ()

                        -- import platform menu
                        import("core.platform.menu")

                        -- get config menu options
                        return menu.options("config")
                    end

                ,   {category = "Other Configuration"}
                ,   {nil, "debugger",   "kv", "auto"    , "The Debugger"                                                    }
                ,   {nil, "ccache",     "kv", true      , "Enable or disable the c/c++ compiler cache."                     }
                ,   {nil, "trybuild",   "kv",   nil     ,   "Enable try-build mode and set the third-party buildsystem tool.",
                                                            "e.g.",
                                                            "    - xmake f --trybuild=auto; xmake",
                                                            "    - xmake f --trybuild=autotools -p android --ndk=xxx; xmake",
                                                            "",
                                                            "the third-party buildsystems:"
                                                        ,   values = {"auto", "make", "autotools", "cmake", "scons", "meson", "bazel", "ninja", "msbuild", "xcodebuild", "ndkbuild"}}
                ,   {nil, "tryconfigs", "kv",   nil     ,   "Set the extra configurations of the third-party buildsystem for the try-build mode.",
                                                            "e.g.",
                                                            "    - xmake f --trybuild=autotools --tryconfigs='--enable-shared=no'"}
                ,   {'o', "buildir",    "kv", "build"   , "Set the build directory."                                        }

                ,   {}
                ,   {nil, "target",     "v" , nil       , "Configure for the given target."
                                                        , values = function (complete, opt) return import("private.utils.complete_helper.targets")(complete, opt) end }
                }
            }



