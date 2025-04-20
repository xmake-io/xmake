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
-- @author      ruki, Arthapz
-- @file        msvc/scanner.lua
--

-- imports
import("core.base.json")
import("core.base.semver")
import("core.project.depend")
import("private.tools.vstool")
import("utils.progress")
import("support")
import("builder")
import(".scanner", {inherit = true})

-- scan module dependencies
function scan_dependency_for(target, sourcefile, opt)

    local msvc = target:toolchain("msvc")
    local compinst = target:compiler("cxx")
    local changed = false
    local dependfile = target:dependfile(sourcefile)
    local compflags = compinst:compflags({sourcefile = sourcefile, target = target, sourcekind = "cxx"}) or {}
    local scandependenciesflag = support.get_scandependenciesflag(target)
    local ifcoutputflag = support.get_ifcoutputflag(target)
    local common_flags = {"-TP", scandependenciesflag}
    local fallbackscanner = target:policy("build.c++.modules.fallbackscanner") or
                            target:policy("build.c++.modules.msvc.fallbackscanner") or
                            target:policy("build.c++.msvc.fallbackscanner")

    depend.on_changed(function ()
        if opt.progress and not target:data("in_project_generator") then
            progress.show(opt.progress, "${color.build.target}<%s> generating.module.deps %s", target:fullname(), sourcefile)
        end
        
        local outputdir = support.get_outputdir(target, sourcefile, {scan = true})
        local jsonfile = path.translate(path.join(outputdir, path.filename(sourcefile) .. ".module.json"))
        if scandependenciesflag and not fallbackscanner then
            local dependency_flags = {jsonfile, sourcefile, ifcoutputflag, outputdir, "-Fo" .. target:objectfile(sourcefile)}
            local dependency_flags = table.join(compflags, common_flags, dependency_flags)
            os.vrunv(compinst:program(), winos.cmdargv(dependency_flags), {envs = msvc:runenvs()})
        else
            fallback_generate_dependencies(target, jsonfile, sourcefile, function(file)
                local ifile = path.translate(path.join(outputdir, path.filename(file) .. ".i"))
                os.vrunv(compinst:program(), table.join(compflags,
                    {"/P", "-TP", file,  "/Fi" .. ifile}), {envs = msvc:runenvs()})
                local content = io.readfile(ifile)
                os.rm(ifile)
                return content
            end)
        end
        changed = true

        local dependinfo = io.readfile(jsonfile)
        return { moduleinfo = dependinfo }
    end, {dependfile = dependfile, files = {sourcefile}, changed = target:is_rebuilt(), values = compflags})
    return changed
end

