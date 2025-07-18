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
-- @author      ruki, Arthapz
-- @file        msvc/support.lua
--

-- imports
import("core.base.semver")
import("core.tool.toolchain")
import("core.project.config")
import("lib.detect.find_tool")
import(".support", {inherit = true})

-- load module support for the current target
function load(target)

    -- enable std modules if c++23 by defaults
    if target:data("c++.msvc.enable_std_import") == nil and target:policy("build.c++.modules.std") then
        local languages = target:get("languages")
        local isatleastcpp23 = false
        for _, language in ipairs(languages) do
            if language:startswith("c++") or language:startswith("cxx") then
                isatleastcpp23 = true
                local version = tonumber(language:match("%d+"))
                if (not version or version <= 20) and not language:match("latest") then
                    isatleastcpp23 = false
                    break
                end
            end
        end
        local stdmodulesdir
        local msvc = target:toolchain("msvc")
        if msvc then
            local vcvars = msvc:config("vcvars")
            if vcvars.VCInstallDir and vcvars.VCToolsVersion and semver.compare(vcvars.VCToolsVersion, "14.35") >= 0 then
                stdmodulesdir = path.join(vcvars.VCInstallDir, "Tools", "MSVC", vcvars.VCToolsVersion, "modules")
            end
        end
        if stdmodulesdir then
            target:data_set("c++.msvc.enable_std_import", isatleastcpp23 and os.isdir(stdmodulesdir))
        end
    end
end

-- flags that doesn't affect bmi generation
function strippeable_flags()

    -- speculative list as there is no resource that list flags that prevent reusability, this list will likely be improve over time
    -- @see https://learn.microsoft.com/en-us/cpp/build/reference/compiler-options-listed-alphabetically?view=msvc-170
    local strippeable_flags = {
        "TP",
        "errorReport",
        "W",
        "w",
        "sourceDependencies",
        "scanDependencies",
        "PD",
        "nologo",
        "MP",
        "internalPartition",
        "interface",
        "ifcOutput",
        "help",
        "headerName",
        "Fp",
        "Fm",
        "Fe",
        "Fd",
        "FC",
        "exportHeader",
        "EP",
        "E",
        "doc",
        "diagnostics",
        "cgthreads",
        "C",
        "analyze",
        "?",
    }
    local splitted_strippeable_flags = {
        "Fo",
        "I",
        "reference",
        "headerUnit",
    }
    return strippeable_flags, splitted_strippeable_flags
end

-- provide toolchain include dir for stl headerunit when p1689 is not supported
function toolchain_includedirs(target)
    for _, toolchain_inst in ipairs(target:toolchains()) do
        if toolchain_inst:name() == "msvc" then
            local vcvars = toolchain_inst:config("vcvars")
            if vcvars.VCInstallDir and vcvars.VCToolsVersion then
                return { path.join(vcvars.VCInstallDir, "Tools", "MSVC", vcvars.VCToolsVersion, "include") }
            end
            break
        end
    end
    raise("msvc toolchain includedirs not found!")
end

function has_two_phase_compilation_support(_)
    return false
end

-- build c++23 standard modules if needed
function get_stdmodules(target, opt)
    opt = opt or {}
    if not target:policy("build.c++.modules.std") then
        return
    end
    local msvc
    if opt.toolchain then
        msvc = toolchain.load("msvc", {plat = opt.toolchain:plat(), arch = opt.toolchain:arch()})
    else
        msvc = target:toolchain("msvc")
    end
    if msvc and msvc:check() then
        local vcvars = msvc:config("vcvars")
        if vcvars.VCInstallDir and vcvars.VCToolsVersion then
            local stdmodulesdir = path.join(vcvars.VCInstallDir, "Tools", "MSVC", vcvars.VCToolsVersion, "modules")
            if os.isdir(stdmodulesdir) then
                return {path.normalize(path.join(stdmodulesdir, "std.ixx")), path.normalize(path.join(stdmodulesdir, "std.compat.ixx"))}
            end
        end
    end
    wprint("std and std.compat modules not found! disabling them for the build")
end

function get_bmi_extension()
    return ".ifc"
end

function get_ifcoutputflag(target)
    local ifcoutputflag = _g.ifcoutputflag
    if ifcoutputflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags({"-ifcOutput", os.tmpfile()}, "cxxflags", {flagskey = "cl_ifc_output"})  then
            ifcoutputflag = "-ifcOutput"
        end
        assert(ifcoutputflag, "compiler(msvc): does not support c++ module flag(/ifcOutput)!")
        _g.ifcoutputflag = ifcoutputflag or false
    end
    return ifcoutputflag or nil
end

function get_ifconlyflag(target)
    local ifconlyflag = _g.ifconlyflag
    if ifconlyflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags({"-ifcOnly"}, "cxxflags", {flagskey = "cl_ifc_only"})  then
            ifconlyflag = "-ifcOnly"
        end
        _g.ifconlyflag = ifconlyflag or false
    end
    return ifconlyflag or nil
end

function get_interfaceflag(target)
    local interfaceflag = _g.interfaceflag
    if interfaceflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-interface", "cxxflags", {flagskey = "cl_interface"}) then
            interfaceflag = "-interface"
        end
        assert(interfaceflag, "compiler(msvc): does not support c++ module flag(/interface)!")
        _g.interfaceflag = interfaceflag or false
    end
    return interfaceflag
end

function get_referenceflag(target)
    local referenceflag = _g.referenceflag
    if referenceflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags({"-reference", "Foo=" .. os.tmpfile()}, "cxxflags", {flagskey = "cl_reference"}) then
            referenceflag = "-reference"
        end
        assert(referenceflag, "compiler(msvc): does not support c++ module flag(/reference)!")
        _g.referenceflag = referenceflag or false
    end
    return referenceflag or nil
end

function get_headernameflag(target)
    local headernameflag = _g.headernameflag
    if headernameflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags({"-std:c++latest", "-exportHeader", "-headerName:quote"}, "cxxflags", {flagskey = "cl_header_name_quote"}) and
        compinst:has_flags({"-std:c++latest", "-exportHeader", "-headerName:angle"}, "cxxflags", {flagskey = "cl_header_name_angle"}) then
            headernameflag = "-headerName"
        end
        _g.headernameflag = headernameflag or false
    end
    return headernameflag or nil
end

function get_headerunitflag(target)
    local headerunitflag = _g.headerunitflag
    if headerunitflag == nil then
        local compinst = target:compiler("cxx")
        local ifcfile = os.tmpfile()
        if compinst:has_flags({"-std:c++latest", "-headerUnit:quote", "foo.h=" .. ifcfile}, "cxxflags", {flagskey = "cl_header_unit_quote"}) and
        compinst:has_flags({"-std:c++latest", "-headerUnit:angle", "foo.h=" .. ifcfile}, "cxxflags", {flagskey = "cl_header_unit_angle"}) then
            headerunitflag = "-headerUnit"
        end
        _g.headerunitflag = headerunitflag or false
    end
    return headerunitflag or nil
end

function get_exportheaderflag(target)
    local exportheaderflag = _g.exportheaderflag
    if exportheaderflag == nil then
        if get_headernameflag(target) then
            exportheaderflag = "-exportHeader"
        end
        _g.exportheaderflag = exportheaderflag or false
    end
    return exportheaderflag or nil
end

function get_scandependenciesflag(target)
    local scandependenciesflag = _g.scandependenciesflag
    if scandependenciesflag == nil then
        local compinst = target:compiler("cxx")
        local scan_dependencies_jsonfile = os.tmpfile() .. ".json"
        if compinst:has_flags("-scanDependencies " .. scan_dependencies_jsonfile, "cxflags", {flagskey = "cl_scan_dependencies",
            on_check = function (ok, errors)
                if os.isfile(scan_dependencies_jsonfile) then
                    ok = true
                end
                if ok and not os.isfile(scan_dependencies_jsonfile) then
                    ok = false
                end
                return ok, errors
            end}) then
            scandependenciesflag = "-scanDependencies"
        end
        _g.scandependenciesflag = scandependenciesflag or false
    end
    return scandependenciesflag or nil
end

function get_cppversionflag(target)
    local cppversionflag = _g.cppversionflag
    if cppversionflag == nil then
        local compinst = target:compiler("cxx")
        local flags = compinst:compflags({target = target})
        cppversionflag = table.find_if(flags, function(v) string.startswith(v, "/std:c++") end) or "/std:c++latest"
    end
    return cppversionflag or nil
end

function get_internalpartitionflag(target)
    local internalpartitionflag = _g.internalpartitionflag
    if internalpartitionflag == nil then
        local compinst = target:compiler("cxx")
        if compinst:has_flags("-internalPartition", "cxxflags", {flagskey = "cl_internal_partition"}) then
            internalpartitionflag = "-internalPartition"
        end
        _g.internalpartitionflag = internalpartitionflag or false
    end
    return internalpartitionflag or nil
end
