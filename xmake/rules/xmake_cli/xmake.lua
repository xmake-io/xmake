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

-- define rule: xmake cli program
rule("xmake.cli")
    on_load(function (target)
        target:set("kind", "binary")
        assert(target:pkg("libxmake"), 'please add_packages("libxmake") to target(%s) first!', target:name())
    end)
    after_install(function (target)

        -- get lua script directory
        local scriptdir = path.join(target:scriptdir(), "src")
        if not os.isfile(path.join(scriptdir, "lua", "main.lua")) then
            import("lib.detect.find_path")
            scriptdir = find_path("lua/main.lua", path.join(target:scriptdir(), "**"))
        end

        -- install xmake-core lua scripts first
        local libxmake = target:pkg("libxmake")
        local programdir = path.join(libxmake:installdir(), "share", "xmake")
        local installdir = path.join(target:installdir(), "share", target:name())
        assert(os.isdir(programdir), "%s not found!", programdir)
        if not os.isdir(installdir) then
            os.mkdir(installdir)
        end
        if scriptdir then
            os.mkdir(path.join(installdir, "plugins"))
            os.vcp(path.join(programdir, "core"), installdir)
            os.vcp(path.join(programdir, "modules"), installdir)
            os.vcp(path.join(programdir, "themes"), installdir)
            os.vcp(path.join(programdir, "plugins", "lua"), path.join(installdir, "plugins"))
            os.vcp(path.join(programdir, "actions", "build", "xmake.lua"), path.join(installdir, "actions", "build", "xmake.lua"))
        else
            os.vcp(path.join(programdir, "*"), installdir)
        end

        -- install xmake/cli lua scripts
        --
        --  - bin
        --    - hello
        --  - share
        --    - hello
        --      - modules
        --        - lua
        --          - main.lua
        --

        if scriptdir then
            os.vcp(path.join(scriptdir, "lua"), path.join(installdir, "modules"))
        end
    end)
    before_run(function (target)
        local scriptdir = path.join(target:scriptdir(), "src")
        if not os.isfile(path.join(scriptdir, "lua", "main.lua")) then
            import("lib.detect.find_path")
            scriptdir = find_path("lua/main.lua", path.join(target:scriptdir(), "**"))
        end
        if scriptdir then
            os.setenv("XMAKE_MODULES_DIR", scriptdir)
        end
        local libxmake = target:pkg("libxmake")
        local programdir = path.join(libxmake:installdir(), "share", "xmake")
        assert(os.isdir(programdir), "%s not found!", programdir)
        os.setenv("XMAKE_PROGRAM_DIR", programdir)
    end)
