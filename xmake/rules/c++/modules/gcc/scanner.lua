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
-- @file        gcc/scanner.lua
--

-- imports
import("core.base.json")
import("core.base.semver")
import("core.project.depend")
import("utils.progress")
import("support")
import("builder")
import(".scanner", {inherit = true})

-- scan module dependencies
function scan_dependency_for(target, sourcefile, opt)

    local compinst = target:compiler("cxx")
    local baselineflags = {"-E", "-x", "c++"}
    local depsformatflag = support.get_depsflag(target, "p1689r5")
    local depsfileflag = support.get_depsfileflag(target)
    local depstargetflag = support.get_depstargetflag(target)
    local dependfile = target:dependfile(sourcefile)
    local changed = false
    local compflags = compinst:compflags({sourcefile = sourcefile, target = target, sourcekind = "cxx"})
    local fallbackscanner = target:policy("build.c++.modules.fallbackscanner") or
                            target:policy("build.c++.modules.gcc.fallbackscanner") or
                            target:policy("build.c++.gcc.fallbackscanner")

    depend.on_changed(function()
        if opt.progress and not os.getenv("XMAKE_IN_COMPILE_COMMANDS_PROJECT_GENERATOR") then
            progress.show(opt.progress, "${color.build.target}<%s> scanning.module.deps %s", target:fullname(), sourcefile)
        end

        local outputdir = support.get_outputdir(target, sourcefile, {scan = true})
        local jsonfile = path.translate(path.join(outputdir, path.filename(sourcefile) .. ".json"))
        local has_depsflags = depsformatflag and depsfileflag and depstargetflag
        if has_depsflags and not fallbackscanner then
            local ifile = path.translate(path.join(outputdir, path.filename(sourcefile) .. ".i"))
            local dfile = path.translate(path.join(outputdir, path.filename(sourcefile) .. ".d"))
            compflags = table.join(baselineflags, compflags or {}, {sourcefile, "-MT", jsonfile, "-MD", "-MF", dfile, depsformatflag, depsfileflag .. jsonfile, depstargetflag .. target:objectfile(sourcefile), "-o", ifile})
            os.vrunv(compinst:program(), compflags)
            os.rm(ifile)
            os.rm(dfile)
        else
            if not has_depsflags then
                wprint("GCC doesn't support module scanning ! using fallback scanner")
            end
            fallback_generate_dependencies(target, jsonfile, sourcefile, function(file)
                -- exclude -fmodule* flags because, when they are set gcc try to find bmi of imported modules but they don't exists a this point of compilation
                local compflags = table.clone(compflags)
                table.remove_if(compflags, function(_, flag) return flag:startswith("-fmodule") end)
                local ifile = path.translate(path.join(outputdir, path.filename(file) .. ".i"))
                compflags = table.join(baselineflags, compflags or {}, {file,  "-o", ifile})
                os.vrunv(compinst:program(), compflags)
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

