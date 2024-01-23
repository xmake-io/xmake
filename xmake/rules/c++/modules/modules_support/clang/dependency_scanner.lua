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
-- @file        clang/dependency_scanner.lua
--

-- imports
import("core.base.json")
import("core.base.semver")
import("core.project.depend")
import("utils.progress")
import("compiler_support")
import(".dependency_scanner", {inherit = true})

-- generate dependency files
function generate_dependencies(target, sourcebatch, opt)
    local compinst = target:compiler("cxx")
    local changed = false
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local dependfile = target:dependfile(sourcefile)
        depend.on_changed(function()
            if opt.progress then
                progress.show(opt.progress, "${color.build.target}<%s> generating.module.deps %s", target:name(), sourcefile)
            end

            local outputdir = compiler_support.get_outputdir(target, sourcefile)
            local jsonfile = path.translate(path.join(outputdir, path.filename(sourcefile) .. ".json"))
            if compiler_support.has_clangscandepssupport(target) and not target:policy("build.c++.clang.fallbackscanner") then
                -- We need absolute path of clang to use clang-scan-deps
                -- See https://clang.llvm.org/docs/StandardCPlusPlusModules.html#possible-issues-failed-to-find-system-headers
                local clang_path = compinst:program()
                if not path.is_absolute(clang_path) then
                    clang_path = compiler_support.get_clang_path(target) or compinst:program()
                end
                local clangscandeps = compiler_support.get_clang_scan_deps(target)
                local compinst = target:compiler("cxx")
                local compflags = compinst:compflags({sourcefile = sourcefile, target = target})
                local flags = table.join({"--format=p1689", "--",
                                         clang_path, "-x", "c++", "-c", sourcefile, "-o", target:objectfile(sourcefile)}, compflags or {})
                vprint(table.concat(table.join(clangscandeps, flags), " "))
                local outdata, errdata = os.iorunv(clangscandeps, flags)
                assert(errdata, errdata)

                io.writefile(jsonfile, outdata)
            else
                fallback_generate_dependencies(target, jsonfile, sourcefile, function(file)
                    local compflags = compinst:compflags({sourcefile = file, target = target})
                    -- exclude -fmodule* and -std=c++/gnu++* flags because,
                    -- when they are set clang try to find bmi of imported modules but they don't exists a this point of compilation
                    table.remove_if(compflags, function(_, flag)
                        return flag:startswith("-fmodule") or flag:startswith("-std=c++") or flag:startswith("-std=gnu++")
                    end)
                    local ifile = path.translate(path.join(outputdir, path.filename(file) .. ".i"))
                    local flags = table.join(compflags or {}, {"-E", "-fkeep-system-includes", "-x", "c++", file, "-o", ifile})
                    os.vrunv(compinst:program(), flags)
                    local content = io.readfile(ifile)
                    os.rm(ifile)
                    return content
                end)
            end
            changed = true

            local rawdependinfo = io.readfile(jsonfile)
            if rawdependinfo then
                local dependinfo = json.decode(rawdependinfo)
                if target:data("cxx.modules.stdlib") == nil then
                    local has_std_modules = false
                    for _, r in ipairs(dependinfo.rules) do
                        for _, required in ipairs(r.requires) do
                            -- it may be `std:utility`, ..
                            -- @see https://github.com/xmake-io/xmake/issues/3373
                            local logical_name = required["logical-name"]
                            if logical_name and (logical_name == "std" or logical_name:startswith("std.") or logical_name:startswith("std:")) then
                                has_std_modules = true
                                break
                            end
                        end

                        if has_std_modules then
                            break
                        end
                    end
                    if has_std_modules then

                        -- we need clang >= 17.0 or use clang stdmodules if the current target contains std module
                        local clang_version = compiler_support.get_clang_version(target)
                        assert((clang_version and semver.compare(clang_version, "17.0") >= 0) or target:policy("build.c++.clang.stdmodules"),
                               [[On llvm <= 16 standard C++ modules are not supported ;
                               they can be emulated through clang modules and supported only on libc++ ;
                               please add -stdlib=libc++ cxx flag or disable strict mode]])

                        -- we use libc++ by default if we do not explicitly specify -stdlib:libstdc++
                        target:data_set("cxx.modules.stdlib", "libc++")
                        compiler_support.set_stdlib_flags(target)
                    end
                end
            end

            return {moduleinfo = rawdependinfo}
        end, {dependfile = dependfile, files = {sourcefile}, changed = target:is_rebuilt()})
    end
    return changed
end

