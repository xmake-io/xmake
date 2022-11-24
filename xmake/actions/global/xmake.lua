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
-- @file        xmake.lua
--

task("global")
    set_category("action")
    on_run("main")
    set_menu {
                usage = "xmake global|g [options] [target]",
                description = "Configure the global options for xmake.",
                shortname = 'g',
                options = {
                    {'c', "clean",          "k",  nil       , "Clean the cached user configs and detection cache."},
                    {nil, "check",          "k",  nil       , "Just ignore detection cache and force to check all, it will reserve the cached user configs."},
                    {nil, "menu",           "k" , nil       , "Configure with a menu-driven user interface."              },
                    {category = "."},
                    {nil, "theme",          "kv", "default" , "The theme name."
                                                          , values = function ()
                                                               return import("core.theme.theme.names")()
                                                           end},
                    {nil, "debugger",       "kv", "auto"    , "The debugger program path."                                },
                    {nil, "ccache",         "kv", nil       , "Enable or disable the c/c++ compiler cache."               },
                    {category = "Build Configuration"},
                    {nil, "build_warning",  "kv", nil       , "Enable the warnings output by default when building."      },
                    {nil, "cachedir",       "kv", nil       , "The global cache directory."                               },

                    -- network configuration
                    {category = "Network Configuration"},
                    {nil, "network",        "kv", "public" , "Set the network mode."
                                                           , values = {"public", "private"}                               },
                    {nil, "insecure-ssl",   "kv", nil      , "Disable to check ssl certificates for downloading."         },
                    {'x', "proxy",          "kv", nil      , "Use proxy on given port. [protocol://]host[:port]"
                                                           , "    e.g."
                                                           , "    - xmake g --proxy='http://host:port'"
                                                           , "    - xmake g --proxy='https://host:port'"
                                                           , "    - xmake g --proxy='socks5://host:port'"                },
                    {nil, "proxy_hosts",    "kv", nil       , "Only enable proxy for the given hosts list, it will enable all if be unset,"
                                                           , "and we can pass match pattern to list:"
                                                           , "    e.g."
                                                           , "    - xmake g --proxy_hosts='github.com,gitlab.*,*.xmake.io'"},
                    {nil, "proxy_pac",      "kv", "pac.lua" , "Set the auto proxy configuration file."
                                                           , "    e.g."
                                                           , "    - xmake g --proxy_pac=pac.lua (in $(globaldir) or absolute path)"
                                                           , "    - function main(url, host)"
                                                           , "          if host == 'github.com' then"
                                                           , "               return true"
                                                           , "          end"
                                                           , "      end"
                                                           , ""
                                                           , "Builtin pac files:"
                                                           , function ()
                                                                local description = {}
                                                                local pacfiles = os.files(path.join(os.programdir(), "scripts", "pac", "*.lua"))
                                                                for _, pacfile in ipairs(pacfiles) do
                                                                    table.insert(description, "    - " .. path.filename(pacfile))
                                                                end
                                                                return description
                                                             end},

                    -- package configuration
                    {category = "Package Configuration"},
                    {nil, "pkg_searchdirs", "kv", nil      , "The search directories of the remote package."
                                                           , "    e.g."
                                                           , "    - xmake g --pkg_searchdirs=/dir1" .. path.envsep() .. "/dir2"},
                    {nil, "pkg_cachedir",   "kv", nil      , "The cache root directory of the remote package."},
                    {nil, "pkg_installdir", "kv", nil      , "The install root directory of the remote package."},

                    -- show platform menu options
                    {category = "Platform Configuration"},
                    function ()
                       import("core.platform.menu")
                       return menu.options("global")
                    end
                }
            }



