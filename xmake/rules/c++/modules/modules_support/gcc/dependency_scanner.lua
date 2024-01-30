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
-- @file        gcc/dependency_scanner.lua
--

-- imports
import("core.base.json")
import("core.base.semver")
import("core.project.depend")
import("utils.progress")
import("compiler_support")
import("builder")
import(".dependency_scanner", {inherit = true})

-- generate dependency files
function generate_dependencies(target, sourcebatch, opt)
    local compinst = target:compiler("cxx")
    local baselineflags = {"-E", "-x", "c++"}
    local depsformatflag = compiler_support.get_depsflag(target, "p1689r5")
    local depsfileflag = compiler_support.get_depsfileflag(target)
    local depstargetflag = compiler_support.get_depstargetflag(target)
    local changed = false
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local dependfile = target:dependfile(sourcefile)
        depend.on_changed(function()
            if opt.progress then
                progress.show(opt.progress, "${color.build.target}<%s> generating.module.deps %s", target:name(), sourcefile)
            end

            local outputdir = compiler_support.get_outputdir(target, sourcefile)
            local jsonfile = path.translate(path.join(outputdir, path.filename(sourcefile) .. ".json"))
            if depsformatflag and depsfileflag and depstargetflag and not target:policy("build.c++.gcc.fallbackscanner") then
                local ifile = path.translate(path.join(outputdir, path.filename(sourcefile) .. ".i"))
                local dfile = path.translate(path.join(outputdir, path.filename(sourcefile) .. ".d"))
                local compflags = compinst:compflags({sourcefile = sourcefile, target = target})
                local flags = table.join(compflags or {}, baselineflags, {sourcefile, "-MT", jsonfile, "-MD", "-MF", dfile, depsformatflag, depsfileflag .. jsonfile, depstargetflag .. target:objectfile(sourcefile), "-o", ifile})
                try{function() return os.iorunv(path.translate(compinst:program()), flags) end}
                os.rm(ifile)
                os.rm(dfile)
            else
                fallback_generate_dependencies(target, jsonfile, sourcefile, function(file)
                    local compflags = compinst:compflags({sourcefile = file, target = target})
                    -- exclude -fmodule* flags because, when they are set gcc try to find bmi of imported modules but they don't exists a this point of compilation
                    table.remove_if(compflags, function(_, flag) return flag:startswith("-fmodule") end)
                    local ifile = path.translate(path.join(outputdir, path.filename(file) .. ".i"))
                    local flags = table.join(baselineflags, compflags or {}, {file,  "-o", ifile})
                    try{function() return os.iorunv(compinst:program(), flags) end}
                    local content = io.readfile(ifile)
                    os.rm(ifile)
                    return content
                end)
            end
            changed = true

            local dependinfo = io.readfile(jsonfile)
            return { moduleinfo = dependinfo }
        end, {dependfile = dependfile, files = {sourcefile}, changed = target:is_rebuilt()})
    end
    return changed
end

