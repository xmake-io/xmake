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
-- @file        msvc/dependency_scanner.lua
--

-- imports
import("core.base.json")
import("core.base.semver")
import("core.project.depend")
import("private.tools.vstool")
import("utils.progress")
import("compiler_support")
import("builder")
import(".dependency_scanner", {inherit = true})

-- generate dependency files
function generate_dependency_for(target, sourcefile, opt)
    local msvc = target:toolchain("msvc")
    local scandependenciesflag = compiler_support.get_scandependenciesflag(target)
    local ifcoutputflag = compiler_support.get_ifcoutputflag(target)
    local common_flags = {"-TP", scandependenciesflag}
    local dependfile = target:dependfile(sourcefile)
    local compinst = target:compiler("cxx")
    local flags = compinst:compflags({sourcefile = sourcefile, target = target}) or {}
    local changed = false

    depend.on_changed(function ()
        progress.show(opt.progress, "${color.build.target}<%s> generating.module.deps %s", target:name(), sourcefile)
        local outputdir = compiler_support.get_outputdir(target, sourcefile)

        local jsonfile = path.join(outputdir, path.filename(sourcefile) .. ".module.json")
        if scandependenciesflag and not target:policy("build.c++.msvc.fallbackscanner") then
            local dependency_flags = {jsonfile, sourcefile, ifcoutputflag, outputdir, "-Fo" .. target:objectfile(sourcefile)}
            local compflags = table.join(flags, common_flags, dependency_flags)
            os.vrunv(compinst:program(), winos.cmdargv(compflags), {envs = msvc:runenvs()})
        else
            fallback_generate_dependencies(target, jsonfile, sourcefile, function(file)
                local ifile = path.translate(path.join(outputdir, path.filename(file) .. ".i"))
                os.vrunv(compinst:program(), table.join(flags,
                    {"/P", "-TP", file,  "/Fi" .. ifile}), {envs = msvc:runenvs()})
                local content = io.readfile(ifile)
                os.rm(ifile)
                return content
            end)
        end
        changed = true

        local dependinfo = io.readfile(jsonfile)
        return { moduleinfo = dependinfo }
    end, {dependfile = dependfile, files = {sourcefile}, changed = target:is_rebuilt(), values = flags})
    return changed
end

