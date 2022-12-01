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
-- @file        scan.lua
--

-- imports
import("core.base.option")

-- get menu options
function menu_options()

    -- description
    local description = "Scan the given or all installed packages."

    -- menu options
    local options =
    {
        {nil, "packages",   "vs", nil, "The packages list (support lua pattern).",
                                       "e.g.",
                                       "    - xrepo scan",
                                       "    - xrepo scan zlib",
                                       "    - xrepo scan zlib bo*"}
    }

    -- show menu options
    local function show_options()

        -- show usage
        cprint("${bright}Usage: $${clear cyan}xrepo scan [options] [packages]")

        -- show description
        print("")
        print(description)

        -- show options
        option.show_options(options, "scan")
    end
    return options, show_options, description
end

-- scan packages
function _scan_packages(packages)

    -- enter working project directory
    local workdir = path.join(os.tmpdir(), "xrepo", "working")
    if not os.isdir(workdir) then
        os.mkdir(workdir)
        os.cd(workdir)
        os.vrunv("xmake", {"create", "-P", "."})
    else
        os.cd(workdir)
    end

    -- do configure first
    local config_argv = {"f", "-c"}
    if option.get("diagnosis") then
        table.insert(config_argv, "-vD")
    end
    os.vrunv("xmake", config_argv)

    -- do scan
    local require_argv = {"require", "--scan"}
    if option.get("yes") then
        table.insert(require_argv, "-y")
    end
    if option.get("verbose") then
        table.insert(require_argv, "-v")
    end
    if option.get("diagnosis") then
        table.insert(require_argv, "-D")
    end
    if packages then
        table.join2(require_argv, packages)
    end
    os.vexecv("xmake", require_argv)
end

-- main entry
function main()
    _scan_packages(option.get("packages"))
end
