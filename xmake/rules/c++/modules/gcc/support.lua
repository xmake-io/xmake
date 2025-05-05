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
-- @file        gcc/support.lua
--

-- imports
import("core.base.json")
import("core.base.semver")
import("core.project.config")
import("lib.detect.find_tool")
import(".support", {inherit = true})

-- get includedirs for stl headers
--
-- $ echo '#include <vector>' | gcc -x c++ -E - | grep '/vector"'
-- # 1 "/usr/include/c++/11/vector" 1 3
-- # 58 "/usr/include/c++/11/vector" 3
-- # 59 "/usr/include/c++/11/vector" 3
--
function _get_toolchain_includedirs_for_stlheaders(includedirs, gcc)
    local tmpfile = os.tmpfile() .. ".cc"
    io.writefile(tmpfile, "#include <vector>")
    local result = try {function () return os.iorunv(gcc, {"-E", "-x", "c++", tmpfile}) end}
    if result then
        for _, line in ipairs(result:split("\n", {plain = true})) do
            line = line:trim()
            if line:startswith("#") and line:find("/vector\"", 1, true) then
                local includedir = line:match("\"(.+)/vector\"")
                if includedir and os.isdir(includedir) then
                    table.insert(includedirs, path.normalize(includedir))
                    break
                end
            end
        end
    end
    os.tryrm(tmpfile)
end

-- load module support for the current target
function load(target)
    local modulesflag = get_modulesflag(target)
    target:add("cxxflags", modulesflag, {force = true, expand = false})

    -- fix cxxabi issue
    -- @see https://github.com/xmake-io/xmake/issues/2716#issuecomment-1225057760
    -- https://github.com/xmake-io/xmake/issues/3855
    local cxx11abi = target:policy("build.c++.modules.gcc.cxx11abi") or
                     target:policy("build.c++.gcc.modules.cxx11abi")
    if cxx11abi then
        target:add("cxxflags", "-D_GLIBCXX_USE_CXX11_ABI=1")
    else
        target:add("cxxflags", "-D_GLIBCXX_USE_CXX11_ABI=0")
    end
end

function has_two_phase_compilation_support(_)
    return false
end

-- flags that doesn't affect bmi generation
function strippeable_flags()
    -- speculative list as there is no resource that list flags that prevent reusability, this list will likely be improve over time
    local strippeable_flags = {
        "O",
        "W",
        "w",
        "Q",
        "fmodule-mapper",
        "fmodules-ts",
        "fmodules",
        "fPIC"
    }
    local splitted_strippeable_flags = {
        "I",
        "isystem",
        "cxx-isystem",
        "framework"
    }
    return strippeable_flags, splitted_strippeable_flags
end

-- provide toolchain include directories for stl headerunit when p1689 is not supported
function toolchain_includedirs(target)
    local includedirs = _g.includedirs
    if includedirs == nil then
        includedirs = {}
        local gcc, toolname = target:tool("cxx")
        assert(toolname == "gcc" or toolname == "gxx")
        _get_toolchain_includedirs_for_stlheaders(includedirs, gcc)
        local _, result = try {function () return os.iorunv(gcc, {"-E", "-Wp,-v", "-xc", os.nuldev()}) end}
        if result then
            for _, line in ipairs(result:split("\n", {plain = true})) do
                line = line:trim()
                if os.isdir(line) then
                    table.insert(includedirs, path.normalize(line))
                elseif line:startswith("End") then
                    break
                end
            end
        end
        _g.includedirs = includedirs
    end
    return includedirs
end

function get_target_module_mapperpath(target)
    local path = path.join(modules_cachedir(target, {mkdir = true}), "..", "mapper.txt")
    if not os.isfile(path) then
        io.writefile(path, "")
    end
    return path
end

function _get_std_module_manifest_path(target)
    local compinst = target:compiler("cxx")
    local modules_json_path, _ = try {
        function()
            return os.iorunv(compinst:program(), {"-print-file-name=libstdc++.modules.json"}, {envs = compinst:runenvs()})
        end
    }
    if modules_json_path then
        modules_json_path = modules_json_path:trim()
        if os.isfile(modules_json_path) then
            return modules_json_path
        end
    end
    -- fallback on custom detection
    -- manifest can be found alongside libstdc++.so

    -- TODO
end

function get_stdmodules(target)
    if not target:policy("build.c++.modules.std") then
        return
    end
    local modules_json_path = _get_std_module_manifest_path(target)
    if not modules_json_path then
        return
    end
    local modules_json = json.loadfile(modules_json_path)
    if modules_json and modules_json.modules and #modules_json.modules > 0 then
        local std_module_files = {}
        local modules_json_dir = path.directory(modules_json_path)
        for _, module_file in ipairs(modules_json.modules) do
            local module_file_path = module_file["source-path"]
            if not path.is_absolute(module_file_path) then
                module_file_path = path.join(modules_json_dir, module_file_path)
            end
            table.insert(std_module_files, module_file_path)
        end
        return std_module_files
    end
end

function get_bmi_extension()
    return ".gcm"
end

function get_modulesflag(target)
    local modulesflag = _g.modulesflag
    if modulesflag == nil then
        local compinst = target:compiler("cxx")
        local gcc_version = get_gcc_version(target)
        -- GCC 12 and earlier version has a option '-fmodules' for Modula-2
        if gcc_version and semver.compare(gcc_version, "12") > 0 then
            if compinst:has_flags("-fmodules", "cxxflags", {flagskey = "gcc_modules"}) then
                modulesflag = "-fmodules"
            elseif compinst:has_flags("-fmodules-ts", "cxxflags", {flagskey = "gcc_modules_ts"}) then
                modulesflag = "-fmodules-ts"
            end
        elseif compinst:has_flags("-fmodules-ts", "cxxflags", {flagskey = "gcc_modules_ts"}) then
            modulesflag = "-fmodules-ts"
        end
        assert(modulesflag, "compiler(gcc): does not support c++ module!")
        _g.modulesflag = modulesflag or false
    end
    return modulesflag or nil
end

function get_moduleheaderflag(target)
    local moduleheaderflag = _g.moduleheaderflag
    if moduleheaderflag == nil then
        -- we need to suppress warnings/errors:
        -- external linkage definition of 'int main(int, char**)' in header module must be declared 'inline'
        local snippet = ""
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-fmodule-header", "cxxflags", {snippet = snippet, flagskey = "gcc_module_header"}) then
            moduleheaderflag = "-fmodule-header="
        end
        _g.moduleheaderflag = moduleheaderflag or false
    end
    return moduleheaderflag or nil
end

function get_moduleonlyflag(target)
    local moduleonlyflag = _g.moduleonlyflag
    if moduleonlyflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-fmodule-only", "cxxflags", {flagskey = "gcc_module_only"}) then
            moduleonlyflag = "-fmodule-only"
        end
        _g.moduleonlyflag = moduleonlyflag or false
    end
    return moduleonlyflag or nil
end

function get_modulemapperflag(target)
    local modulemapperflag = _g.modulemapperflag
    if modulemapperflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-fmodule-mapper=" .. os.tmpfile(), "cxxflags", {flagskey = "gcc_module_mapper"}) then
            modulemapperflag = "-fmodule-mapper="
        end
        assert(modulemapperflag, "compiler(gcc): does not support c++ module!")
        _g.modulemapperflag = modulemapperflag or false
    end
    return modulemapperflag or nil
end

function get_depsflag(target)
    local depflag = _g.depflag
    if depflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-fdeps-format=p1689r5", "cxxflags", {flagskey = "gcc_deps_format",
         on_check = function (ok, errors)
             if errors:find("-M") then
                ok = true
             end
             return ok, errors
        end}) then
            depflag = "-fdeps-format=p1689r5"
        end
        _g.depflag = depflag or false
    end
    return depflag or nil
end

function get_depsfileflag(target)
    local depfileflag = _g.depfileflag
    if depfileflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-fdeps-file=" .. os.tmpfile(), "cxxflags", {flagskey = "gcc_deps_file",
         on_check = function (ok, errors)
             if errors:find("-M") then
                ok = true
             end
             return ok, errors
        end}) then
            depfileflag = "-fdeps-file="
        end
        _g.depfileflag = depfileflag or false
    end
    return depfileflag or nil
end

function get_depstargetflag(target)
    local depoutputflag = _g.depoutputflag
    if depoutputflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-fdeps-target=" .. os.tmpfile() .. ".o", "cxxflags", {flagskey = "gcc_deps_output",
         on_check = function (ok, errors)
             if errors:find("-M") then
                ok = true
             end
             return ok, errors
        end}) then
            depoutputflag = "-fdeps-target="
        end
        _g.depoutputflag = depoutputflag or false
    end
    return depoutputflag or nil
end

function get_cppversionflag(target)
    local cppversionflag = _g.cppversionflag
    if cppversionflag == nil then
        local compinst = target:compiler("cxx")
        local flags = compinst:compflags({target = target})
        cppversionflag = table.find_if(flags, function(v) string.startswith(v, "-std=c++") end) or "-std=c++20"
        _g.cppversionflag = cppversionflag
    end
    return cppversionflag or nil
end

function get_gcc_version(target)
    local gcc_version = _g.gcc_version
    if not gcc_version then
        local program, toolname = target:tool("cxx")
        if program and toolname:startswith("gcc") then
            local gcc = find_tool(toolname, {program = program, version = true,
                envs = os.getenvs(), cachekey = "modules_support_gcc_" .. toolname})
            if gcc then
                gcc_version = gcc.version
            end
        end
        gcc_version = gcc_version or false
        _g.gcc_version = gcc_version
    end
    return gcc_version or nil
end
