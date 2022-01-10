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

-- references:
--
-- https://github.com/xmake-io/xmake/issues/1622
-- http://www.swig.org/Doc4.0/SWIGDocumentation.html#Introduction_nn4
--

rule("swig.base")
    on_load(function (target)
        target:set("kind", "shared")
        local moduletype = target:extraconf("rules", "swig.c", "moduletype") or target:extraconf("rules", "swig.cpp", "moduletype")
        if moduletype == "python" then
            target:set("prefixname", "_")
            local soabi = target:extraconf("rules", "swig.c", "soabi") or target:extraconf("rules", "swig.cpp", "soabi")
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
        elseif moduletype == "lua" then
            target:set("prefixname", "")
            if not target:is_plat("windows") then
                target:set("extension", ".so")
            end
        else
            raise("unknown swig module type, please use `add_rules(\"swig.c\", {moduletype = \"python\"})` to set it!")
        end
        local scriptfiles = {}
        for _, sourcebatch in pairs(target:sourcebatches()) do
            if sourcebatch.rulename:startswith("swig.") then
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    local scriptdir
                    local fileconfig = target:fileconfig(sourcefile)
                    if fileconfig then
                        scriptdir = fileconfig.scriptdir
                    end
                    local scriptfile = path.join(target:autogendir(), "rules", "swig", path.basename(sourcefile))
                    if moduletype == "python" then
                        scriptfile = scriptfile .. ".py"
                    elseif moduletype == "lua" then
                        scriptfile = scriptfile .. ".lua"
                    end
                    table.insert(scriptfiles, scriptfile)
                    if scriptdir then
                        target:add("installfiles", scriptfile, {prefixdir = scriptdir})
                    end
                end
            end
        end
        -- for custom on_install/after_install, user can use it to install them
        target:data_set("swig.scriptfiles", scriptfiles)
        target:data_set("swig.moduletype", moduletype)
    end)

rule("swig.c")
    set_extensions(".i")
    add_deps("swig.base", "c.build")
    on_buildcmd_file(function (target, batchcmds, sourcefile, opt)
        import("build_module_file")(target, batchcmds, sourcefile, table.join({sourcekind = "cc"}, opt))
    end)

rule("swig.cpp")
    set_extensions(".i")
    add_deps("swig.base", "c++.build")
    on_buildcmd_file(function (target, batchcmds, sourcefile, opt)
        import("build_module_file")(target, batchcmds, sourcefile, table.join({sourcekind = "cxx"}, opt))
    end)


