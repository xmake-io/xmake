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

-- define rule: xmake cli program
rule("xmake.cli")
    before_load(function (target)
        target:set("kind", "binary")
        assert(target:pkg("libxmake"), 'please add_packages("libxmake") to target(%s) first!', target:name())
    end)
    after_install(function (target)
        -- install xmake/cli program
        --
        --  - bin
        --    - hello
        --  - share
        --    - hello
        --      - lua
        --        - main.lua
        --      - core
        --        - ..
        --
        local scriptdir = path.join(target:scriptdir(), "src")
        if not os.isfile(path.join(scriptdir, "lua", "main.lua")) then
            import("lib.detect.find_path")
            scriptdir = assert(find_path("lua/main.lua", path.join(target:scriptdir(), "**")), "lua/main.lua not found!")
        end
        local installdir = path.join(target:installdir(), "share", target:name())
        if not os.isdir(installdir) then
            os.mkdir(installdir)
        end
        os.vcp(path.join(scriptdir, "lua"), installdir)

        -- install xmake-core lua scripts
        local libxmake = target:pkg("libxmake")
        local programdir = path.join(path.directory(libxmake:get("linkdirs")), "share", "xmake")
        assert(os.isdir(programdir), "%s not found!", programdir)
        local coredir = path.join(installdir, "core")
        if not os.isdir(coredir) then
            os.mkdir(coredir)
        end
        os.vcp(path.join(programdir, "*"), coredir)
    end)
    before_run(function (target)
        local scriptdir = path.join(target:scriptdir(), "src")
        if not os.isfile(path.join(scriptdir, "lua", "main.lua")) then
            import("lib.detect.find_path")
            scriptdir = assert(find_path("lua/main.lua", path.join(target:scriptdir(), "**")), "lua/main.lua not found!")
        end
        local libxmake = target:pkg("libxmake")
        local programdir = path.join(path.directory(libxmake:get("linkdirs")), "share", "xmake")
        assert(os.isdir(programdir), "%s not found!", programdir)
        os.setenv("XMAKE_PROGRAM_DIR", programdir)
        os.setenv("XMAKE_MODULES_DIR", scriptdir)
    end)
