--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        cmakelists.lua
--

-- imports
import("core.tool.compiler")
import("core.project.project")
import("core.language.language")
import("core.platform.platform")

-- make common flags
function _make_common_flags(target, sourcekind, sourcebatch)

    -- make source flags
    local sourceflags = {}
    local flags_stats = {}
    local files_count = 0
    local first_flags = nil
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do

        -- make compiler flags
        local flags = compiler.compflags(sourcefile, {target = target, sourcekind = sourcekind})
        for _, flag in ipairs(flags) do
            flags_stats[flag] = (flags_stats[flag] or 0) + 1
        end

        -- update files count
        files_count = files_count + 1

        -- save first flags
        if first_flags == nil then
            first_flags = flags
        end

        -- save source flags
        sourceflags[sourcefile] = flags
    end

    -- make common flags
    local commonflags = {}
    for _, flag in ipairs(first_flags) do
        if flags_stats[flag] == files_count then
            table.insert(commonflags, flag)
        end
    end

    -- remove common flags from source flags
    local sourceflags_ = {}
    for sourcefile, flags in pairs(sourceflags) do
        local otherflags = {}
        for _, flag in ipairs(flags) do
            if flags_stats[flag] ~= files_count then
                table.insert(otherflags, flag)
            end
        end
        sourceflags_[sourcefile] = otherflags
    end

    -- ok?
    return commonflags, sourceflags_
end

-- make project info
function _make_project(cmakelists)
    cmakelists:print("# project")
    cmakelists:print("cmake_minimum_required(VERSION 3.1.0)")
    local project_name = project.name()
    if project_name then
        local project_info = ""
        local project_version = project.version()
        if project_version then
            project_info = project_info .. " VERSION " .. project_version
        end
        cmakelists:print("project(%s%s)", project_name, project_info)
    end
    cmakelists:print("")
end

-- make phony
function _make_phony(cmakelists, target)

    -- make dependence for the dependent targets
    cmakelists:printf("add_custom_target(%s", target:name())
    local deps = target:get("deps")
    if deps then
        cmakelists:write(" DEPENDS")
        for _, dep in ipairs(deps) do
            cmakelists:write(" " .. dep)
        end
    end
    cmakelists:print(")")
    cmakelists:print("")
end

-- make target
function _make_target(cmakelists, target, targetflags)

    -- is phony target?
    if target:isphony() then
        return _make_phony(cmakelists, target)
    end

end

-- make all
function _make_all(cmakelists)

    -- make project info
    _make_project(cmakelists)

    -- make variables for source kinds
    cmakelists:print("# compilers")
    for sourcekind, _ in pairs(language.sourcekinds()) do
        local program = platform.tool(sourcekind)
        if program and program ~= "" then
            cmakelists:print("set(%s %s)", sourcekind:upper(), program)
        end
    end
    cmakelists:print("")

    -- make variables for linker kinds
    cmakelists:print("# linkers")
    local linkerkinds = {}
    for _, _linkerkinds in pairs(language.targetkinds()) do
        table.join2(linkerkinds, _linkerkinds)
    end
    for _, linkerkind in ipairs(table.unique(linkerkinds)) do
        local program = platform.tool(linkerkind)
        if program and program ~= "" then
            cmakelists:print("set(%s %s)", (linkerkind:upper():gsub('%-', '_')), program)
        end
    end
    cmakelists:print("")

    -- TODO
    -- disable precompiled header first
    for _, target in pairs(project.targets()) do
        target:set("pcheader", nil)
        target:set("pcxxheader", nil)
    end

    -- make variables for target flags
    cmakelists:print("# common flags")
    local targetflags = {}
    for targetname, target in pairs(project.targets()) do
        if not target:isphony() then
            for sourcekind, sourcebatch in pairs(target:sourcebatches()) do
                if not sourcebatch.rulename then
                    local commonflags, sourceflags = _make_common_flags(target, sourcekind, sourcebatch)
                    cmakelists:print("set(%s_%s %s)", targetname, sourcekind:upper(), os.args(commonflags))
                    targetflags[targetname .. '_' .. sourcekind:upper()] = sourceflags
                end
            end
        end
    end
    cmakelists:print("")

    -- make it for all targets
    cmakelists:print("# targets")
    for _, target in pairs(project.targets()) do
        _make_target(cmakelists, target, targetflags)
    end
end

-- make
function make(outputdir)

    -- enter project directory
    local oldir = os.cd(os.projectdir())

    -- open the cmakelists
    local cmakelists = io.open(path.join(outputdir, "CMakeLists.txt"), "w")

    -- make all
    _make_all(cmakelists)

    -- close the cmakelists
    cmakelists:close()
 
    -- leave project directory
    os.cd(oldir)
end
