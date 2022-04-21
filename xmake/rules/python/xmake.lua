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

-- @see https://github.com/xmake-io/xmake/issues/1896
rule("python.library")
    on_load(function (target)
        target:set("kind", "shared")
        target:set("prefixname", "")
        local soabi = target:extraconf("rules", "python.library", "soabi")
        if soabi then
            import("lib.detect.find_tool")
            local python = assert(find_tool("python3"), "python not found!")
            local result = try { function() return os.iorunv(python.program, {"-c", "import sysconfig; print(sysconfig.get_config_var('EXT_SUFFIX'))"}) end}
            if result then
                result = result:trim()
                if result ~= "None" then
                    target:set("extension", result)
                end
            end
        else
            if target:is_plat("windows") then
                target:set("extension", ".pyd")
            end
        end
    end)
    after_build(function(target)
        local targetfile = target:targetfile()
        os.cp(targetfile, path.join("./", path.filename(targetfile)))
        local setuptools = target:extraconf("rules", "python.library", "setuptools")
        if setuptools then
          print("python setup.py develop")
          os.run("python setup.py develop")
        end
    end)

