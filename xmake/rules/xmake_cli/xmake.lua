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
    before_run(function (target)
        local libxmake = target:pkg("libxmake")
        local programdir = path.join(path.directory(libxmake:get("linkdirs")), "share", "xmake")
        assert(os.isdir(programdir), "%s not found!", programdir)
        os.setenv("XMAKE_PROGRAM_DIR", programdir)
        os.setenv("XMAKE_MODULES_DIR", path.join(target:scriptdir(), "src"))
    end)
