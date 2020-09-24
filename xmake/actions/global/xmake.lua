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
task("global")

    -- set category
    set_category("action")

    -- on run
    on_run("main")

    -- set menu
    set_menu {
                -- usage
                usage = "xmake global|g [options] [target]"

                -- description
            ,   description = "Configure the global options for xmake."

                -- xmake g
            ,   shortname = 'g'

                -- options
            ,   options =
                {
                    {'c', "clean",          "k" , nil       , "Clean the cached configure and configure all again."       }
                ,   {nil, "menu",           "k" , nil       , "Configure with a menu-driven user interface."              }
                ,   {category = "."}
                ,   {nil, "theme",          "kv", "default" , "The theme name."
                                                           , values = function ()
                                                                return import("core.theme.theme.names")()
                                                            end}
                ,   {nil, "debugger",       "kv", "auto"    , "The debugger program path."                                }

                    -- network configuration
                ,   {category = "Network Configuration"}
                ,   {nil, "network",        "kv", "public"  , "Set the network mode."
                                                            , values = {"public", "private"}                              }
                ,   {'x', "proxy",          "kv", nil       , "Use proxy on given port. [protocol://]host[:port]"
                                                            , "    e.g."
                                                            , "    - xmake g --proxy='http://host:port'"
                                                            , "    - xmake g --proxy='https://host:port'"
                                                            , "    - xmake g --proxy='socks5://host:port'"                }
                ,   {nil, "proxy_hosts",    "kv", nil       , "Only enable proxy for the given hosts list, it will enable all if be unset,"
                                                            , "and we can pass match pattern to list:"
                                                            , "    e.g."
                                                            , "    - xmake g --proxy_hosts='github.com,gitlab.*,*.xmake.io'"}
                ,   {nil, "proxy_pac",      "kv", "pac.lua" , "Set the auto proxy configuration file."
                                                            , "    e.g."
                                                            , "    - xmake g --proxy_pac=pac.lua (in $(globaldir) or absolute path)"
                                                            , "    - function main(url, host)"
                                                            , "          if host == 'github.com' then"
                                                            , "               return true"
                                                            , "          end"
                                                            , "      end"}

                    -- package configuration
                ,   {category = "Package Configuration"}
                ,   {nil, "pkg_searchdirs", "kv", nil       , "The search directories of the remote package."
                                                            , "    e.g."
                                                            , "    - xmake g --pkg_searchdirs=/dir1" .. path.envsep() .. "/dir2"}
                ,   {nil, "pkg_installdir", "kv", nil       , "The install root directory of the remote package."         }

                    -- show platform menu options
                ,   {category = "Platform Configuration"}
                ,   function ()

                        -- import platform menu
                        import("core.platform.menu")

                        -- get global menu options
                        return menu.options("global")
                    end

                }
            }



