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
-- @file        clang/scanner.lua
--

-- imports
import("core.base.json")
import("core.base.semver")
import("core.base.option")
import("core.project.depend")
import("utils.progress")
import("support")
import(".scanner", {inherit = true})

-- scan module dependencies
function scan_dependency_for(target, sourcefile, opt)

    local compinst = target:compiler("cxx")
    local changed = false
    local dependfile = target:dependfile(sourcefile)
    local compflags = compinst:compflags({sourcefile = sourcefile, target = target, sourcekind = "cxx"})

    depend.on_changed(function()
        if opt.progress and not os.getenv("XMAKE_IN_COMPILE_COMMANDS_PROJECT_GENERATOR") then
            progress.show(opt.progress, "${color.build.target}<%s> generating.module.deps %s", target:fullname(), sourcefile)
        end

        local outputdir = support.get_outputdir(target, sourcefile, {scan = true})
        local jsonfile = path.translate(path.join(outputdir, path.filename(sourcefile) .. ".json"))
        local has_clangscandepssupport = support.has_clangscandepssupport(target)
        local fallbackscanner = target:policy("build.c++.modules.fallbackscanner") or
                                target:policy("build.c++.modules.clang.fallbackscanner") or
                                target:policy("build.c++.clang.fallbackscanner")
        if has_clangscandepssupport and not fallbackscanner then
            -- We need absolute path of clang to use clang-scan-deps
            -- See https://clang.llvm.org/docs/StandardCPlusPlusModules.html#possible-issues-failed-to-find-system-headers
            local clang_path = compinst:program()
            if not path.is_absolute(clang_path) then
                clang_path = support.get_clang_path(target) or compinst:program()
            end
            local clangscandeps = support.get_clang_scan_deps(target)
            local dependency_flags = table.join({"--format=p1689", "--",
                                                 clang_path, "-x", "c++"}, compflags, {"-c", sourcefile, "-o", target:objectfile(sourcefile)})
            if option.get("verbose") then
                print(os.args(table.join(clangscandeps, dependency_flags)))
            end
            local outdata, errdata = os.iorunv(clangscandeps, dependency_flags)
            assert(outdata, errdata)

            io.writefile(jsonfile, outdata)
        else
            if not has_clangscandepssupport then
                wprint("No clang-scan-deps found ! using fallback scanner")
            end
            fallback_generate_dependencies(target, jsonfile, sourcefile, function(file)
                local keepsystemincludesflag = support.get_keepsystemincludesflag(target)
                local compflags = table.clone(compflags)
                -- exclude -fmodule* and -std=c++/gnu++* flags because
                -- when they are set clang try to find bmi of imported modules but they don't exists in this point of compilation
                table.remove_if(compflags, function(_, flag)
                    return flag:startswith("-fmodule") or flag:startswith("-fvisibility") or flag:startswith("-std=c++") or flag:startswith("-std=gnu++")
                end)
                local ifile = path.translate(path.join(outputdir, path.filename(file) .. ".i"))
                compflags = table.join(compflags or {}, keepsystemincludesflag or {}, {"-E", "-x", "c++", file, "-o", ifile})
                os.vrunv(compinst:program(), compflags)
                local content = io.readfile(ifile)
                os.rm(ifile)
                return content
            end)
        end
        changed = true

        local rawdependinfo = io.readfile(jsonfile)
        return {moduleinfo = rawdependinfo}
    end, {dependfile = dependfile, files = {sourcefile}, changed = target:is_rebuilt(), values = compflags})
    return changed
end

