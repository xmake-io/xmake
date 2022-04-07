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
-- @file        envs.lua
--

-- imports
import("core.base.text")
import("core.base.global")
import("core.project.config")
import("core.project.project")

-- show all toolchains
function main()

    local envs = {  XMAKE_PROGRAM_DIR    = {"Set the program scripts directory of xmake.", os.programdir()},
                    XMAKE_CONFIGDIR      = {"Set the local config directory of project.", config.directory()},
                    XMAKE_GLOBALDIR      = {"Set the global config directory of xmake.", global.directory()},
                    XMAKE_COLORTERM      = {"Set the color terminal environment.", os.getenv("XMAKE_COLORTERM") or os.getenv("COLORTERM")},
                    XMAKE_LOGFILE        = {"Set the log output file path.", os.getenv("XMAKE_LOGFILE")},
                    XMAKE_ROOT           = {"Allow xmake to run under root.", os.getenv("XMAKE_ROOT")},
                    XMAKE_RAMDIR         = {"Set the ramdisk directory.", os.getenv("XMAKE_RAMDIR")},
                    XMAKE_RCFILES        = {"Set the runtime configuration files.", path.joinenv(project.rcfiles())},
                    XMAKE_TMPDIR         = {"Set the temporary directory.", os.tmpdir()},
                    XMAKE_PROFILE        = {"Start profiler, e.g. perf, trace, stuck.", os.getenv("XMAKE_PROFILE")},
                    XMAKE_PKG_CACHEDIR   = {"Set the cache directory of packages.", os.getenv("XMAKE_PKG_CACHEDIR")},
                    XMAKE_PKG_INSTALLDIR = {"Set the install directory of packages.", os.getenv("XMAKE_PKG_INSTALLDIR")}}
    local width = 24
    for name, env in pairs(envs) do
        cprint("${color.dump.string}%s${clear}%s%s", name, (" "):rep(width - #name), env[1])
        cprint("%s${bright}%s", (" "):rep(width), env[2] or "<empty>")
    end
end
