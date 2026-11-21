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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        config.lua
--

-- imports
import("core.project.depend")
import("generator.csproj", {rootdir = os.scriptdir(), alias = "generate_csproj"})
import("references", {rootdir = os.scriptdir(), alias = "get_references"})

function main(target)

    -- compute csproj path
    local csprojfile = path.join(target:autogendir(), "rules", "csharp", target:name() .. ".csproj")
    local dependfile = target:dependfile(csprojfile)

    -- collect source files and dep csproj paths as depend values
    local sourcefiles = target:sourcefiles()
    local depcsproj = {}
    for _, dep in ipairs(target:orderdeps()) do
        local depcsproj_path = dep:data("csharp.csproj")
        if depcsproj_path then
            table.insert(depcsproj, depcsproj_path)
        end
    end

    local references = {}
    local assemblyfiles = {}
    for _, refinfo in ipairs(get_references(target)) do
        table.insert(references, refinfo.name .. "=" .. (refinfo.assemblyfile or ""))
        if refinfo.assemblyfile then
            table.insert(assemblyfiles, refinfo.assemblyfile)
        end
    end

    -- generate csproj incrementally
    depend.on_changed(function ()
        generate_csproj(target, csprojfile)
    end, {dependfile = dependfile, files = sourcefiles, values = table.join(depcsproj, references)})

    target:data_set("csharp.csproj", csprojfile)
    target:data_set("csharp.assemblyfiles", assemblyfiles)

    -- add native shared library search paths for P/Invoke
    for _, dep in ipairs(target:orderdeps()) do
        if dep:is_shared() and not dep:rule("csharp.build") then
            if is_host("windows") then
                target:add("runenvs", "PATH", dep:targetdir())
            elseif is_host("macosx") then
                target:add("runenvs", "DYLD_LIBRARY_PATH", dep:targetdir())
            else
                target:add("runenvs", "LD_LIBRARY_PATH", dep:targetdir())
            end
        end
    end
end
