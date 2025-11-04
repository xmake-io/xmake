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
-- @file        toolchain.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.base.semver")
import("core.tool.linker")
import("core.tool.compiler")
import("core.language.language")
import("lib.detect.find_tool")
import("detect.sdks.find_vstudio")

-- attempt to check vs environment
function _check_vsenv(toolchain, check)

    -- have been checked?
    local vs = toolchain:config("vs") or config.get("vs")
    if vs then
        vs = tostring(vs)
    end
    local vcvars = toolchain:config("vcvars")
    if vs and vcvars then
        return vs
    end

    -- find vstudio
    local vs_toolset = toolchain:config("vs_toolset") or config.get("vs_toolset")
    local vs_sdkver  = toolchain:config("vs_sdkver") or config.get("vs_sdkver")
    local vstudio = find_vstudio({toolset = vs_toolset, sdkver = vs_sdkver})
    if vstudio then

        -- make order vsver
        local vsvers = {}
        for vsver, _ in pairs(vstudio) do
            if not vs or vs ~= vsver then
                table.insert(vsvers, vsver)
            end
        end
        table.sort(vsvers, function (a, b) return tonumber(a) > tonumber(b) end)
        if vs then
            table.insert(vsvers, 1, vs)
        end

        -- get vcvarsall
        for _, vsver in ipairs(vsvers) do
            local vcvarsall = (vstudio[vsver] or {}).vcvarsall or {}
            local vcvars = vcvarsall[toolchain:arch()]
            if vcvars and vcvars.PATH and vcvars.INCLUDE and vcvars.LIB then
                toolchain:config_set("vcvars", vcvars)
                toolchain:config_set("vcarchs", table.orderkeys(vcvarsall))
                toolchain:config_set("vs_toolset", vcvars.VCToolsVersion)
                toolchain:config_set("vs_sdkver", vcvars.WindowsSDKVersion)
                if check and check(toolchain, vcvars) then
                    return vsver
                end
            end
        end
    end
end

-- check the visual studio
function check_vstudio(toolchain, check)
    local vs = _check_vsenv(toolchain, check)
    if vs then
        if toolchain:is_global() then
            config.set("vs", vs, {force = true, readonly = true})
        end
        toolchain:config_set("vs", vs)
        cprint("checking for Microsoft Visual Studio (%s) version ... ${color.success}%s", toolchain:arch(), vs)
    else
        cprint("checking for Microsoft Visual Studio (%s) version ... ${color.nothing}${text.nothing}", toolchain:arch())
    end
    return vs
end

-- check vc build tools sdk
function check_vc_build_tools(toolchain, sdkdir, check)
    local opt = {}
    opt.sdkdir = sdkdir
    opt.vs_toolset = toolchain:config("vs_toolset") or config.get("vs_toolset")
    opt.vs_sdkver = toolchain:config("vs_sdkver") or config.get("vs_sdkver")

    local vcvarsall = find_vstudio.find_build_tools(opt)
    if not vcvarsall then
        return
    end

    local vcvars = vcvarsall[toolchain:arch()]
    if vcvars and vcvars.PATH and vcvars.INCLUDE and vcvars.LIB then
        toolchain:config_set("vcvars", vcvars)
        toolchain:config_set("vcarchs", table.orderkeys(vcvarsall))
        toolchain:config_set("vs_toolset", vcvars.VCToolsVersion)
        toolchain:config_set("vs_sdkver", vcvars.WindowsSDKVersion)
        if check and check(toolchain, vcvars) then
            return vcvars
        end
    end
end

-- is the compatible with the host?
function is_compatible_with_host(name)
    if is_host("linux", "macosx", "bsd") then
        if name:startswith("clang") or name:startswith("gcc") or name == "llvm" then
            return true
        end
    elseif is_host("windows") then
        if name == "msvc" or name == "llvm" or name == "clang-cl" then
            return true
        end
    end
end

-- get vs version
function get_vsver(vs)
    local vsvers = {["2026"] = "18",
                    ["2022"] = "17",
                    ["2019"] = "16",
                    ["2017"] = "15",
                    ["2015"] = "14",
                    ["2013"] = "12",
                    ["2012"] = "11",
                    ["2010"] = "10",
                    ["2008"] = "9",
                    ["2005"] = "8"}
    return assert(vsvers[vs], "unknown msvc version!")
end

-- get vs toolset version, e.g. v143, v144, ..
function get_vs_toolset_ver(vs_toolset)
    local toolset_ver
    if vs_toolset then
        local verinfo = semver.new(vs_toolset)
        toolset_ver = "v" .. verinfo:major() .. (tostring(verinfo:minor()):sub(1, 1) or "0")

        -- @see https://github.com/xmake-io/xmake/pull/5176
        if toolset_ver and toolset_ver == "v144" and verinfo:ge("14.40") and verinfo:lt("14.50") then
            toolset_ver = "v143"
        end
    end
    return toolset_ver
end

-- map compiler flags for package
function map_compflags_for_package(package, langkind, name, values)
    -- @note we need to patch package:sourcekinds(), because it wiil be called nf_runtime for gcc/clang
    package.sourcekinds = function (self)
        local sourcekind = language.langkinds()[langkind]
        return sourcekind
    end
    local flags = compiler.map_flags(langkind, name, values, {target = package})
    package.sourcekinds = nil
    return flags
end

-- map linker flags for package
function map_linkflags_for_package(package, targetkind, sourcekinds, name, values)
    -- @note we need to patch package:sourcekinds(), because it wiil be called nf_runtime for gcc/clang
    package.sourcekinds = function (self)
        return sourcekinds
    end
    local flags = linker.map_flags(targetkind, sourcekinds, name, values, {target = package})
    package.sourcekinds = nil
    return flags
end

-- get llvm sdk resource directory
function _get_llvm_resourcedir(toolchain)
    local llvm_resourcedir = _g._LLVM_resourceDIR
    if llvm_resourcedir == nil then
        local outdata = try { function() return os.iorunv(toolchain:get("cc"), {"-print-resource-dir"}, {envs = toolchain:runenvs()}) end }
        if outdata then
            llvm_resourcedir = path.normalize(outdata:trim())
            if not os.isdir(llvm_resourcedir) then
                llvm_resourcedir = nil
            end
        end
        _g._LLVM_resourceDIR = llvm_resourcedir or false
    end
    return llvm_resourcedir or nil
end

-- get llvm sdk root directory
function _get_llvm_rootdir(self)
    local llvm_rootdir = _g._LLVM_ROOTDIR
    if llvm_rootdir == nil then
        local resourcedir = _get_llvm_resourcedir(self)
        if resourcedir then
            llvm_rootdir = path.normalize(path.join(resourcedir, "..", "..", ".."))
            if not os.isdir(llvm_rootdir) then
                llvm_rootdir = nil
            end
        end
        _g._LLVM_ROOTDIR = llvm_rootdir or false
    end
    return llvm_rootdir or nil
end

-- find compiler-rt dir
function _get_llvm_compiler_win_rtdir_and_link(self, target)
    import("lib.detect.find_tool")

    local cc = self:get("cc")
    local cc_tool = find_tool(cc, {version = true})
    if cc_tool and cc_tool.version then
        local resdir = _get_llvm_resourcedir(self)
        if resdir  then
            local res_libdir = path.join(resdir, "lib")
            -- when -DLLVM_ENABLE_TARGET_RUNTIME_DIR=OFF rtdir is windows/ and rtlink is clang_rt.builtinsi_<arch>.lib  
            -- when ON rtdir is windows/<target-triple> and rtlink is clang_rt.builtins.lib
            local target_triple = _get_llvm_target_triple(self)
            local arch = target_triple and target_triple:split("-")[1]

            local tripletdir = target_triple and path.join(res_libdir, "windows", target_triple)
            tripletdir = os.isdir(tripletdir) or nil

            local rtdir = tripletdir and path.join("windows", target_triple) or "windows"
            if os.isdir(path.join(res_libdir, rtdir)) then
                local rtlink = "clang_rt.builtins" .. (tripletdir and ".lib" or ("-" .. arch .. ".lib"))
                if os.isfile(path.join(res_libdir, rtdir, rtlink)) then
                    return res_libdir, path.join(rtdir, rtlink)
                end
            end
            return res_libdir
        end
    end
end

-- get llvm target triple
function _get_llvm_target_triple(self)
    local llvm_targettriple = _g._LLVM_TARGETTRIPLE
    if llvm_targettriple == nil then
        local outdata = try { function() return os.iorunv(self:program(), {"-print-target-triple"}, {envs = self:runenvs()}) end }
        if outdata then
            llvm_targettriple = outdata:trim()
        end
        _g._LLVM_TARGETTRIPLE = llvm_targettriple or false
    end
    return llvm_targettriple or nil
end

-- get llvm toolchain dirs
function get_llvm_dirs(toolchain)
    local llvm_dirs = _g.llvm_dirs
    if llvm_dirs == nil then
        local rootdir = toolchain:sdkdir()
        if not rootdir and toolchain:is_plat("windows") then
            rootdir = _get_llvm_rootdir(toolchain)
        end

        local bindir, libdir, cxxlibdir, includedir, cxxincludedir, resdir, rtdir, rtlink
        if rootdir then
            bindir = path.join(rootdir, "bin")
            if bindir then
                bindir = os.isdir(bindir) and bindir or nil
            end

            libdir = path.join(rootdir, "lib")
            if libdir then
                libdir = os.isdir(libdir) and libdir or nil
            end

            if libdir then
                cxxlibdir = libdir and path.join(libdir, "c++")
                if cxxlibdir then
                    cxxlibdir = os.isdir(cxxlibdir) and cxxlibdir or nil
                end
            end

            includedir = path.join(rootdir, "include")
            if includedir then
                includedir = os.isdir(includedir) and includedir or nil
            end

            if includedir then
                cxxincludedir = includedir and path.join(includedir, "c++", "v1") or nil
                if cxxincludedir then
                    cxxincludedir = os.isdir(cxxincludedir) and cxxincludedir or nil
                end
            end

            resdir = _get_llvm_resourcedir(toolchain)
            if toolchain:is_plat("windows") then
                rtdir, rtlink = _get_llvm_compiler_win_rtdir_and_link(toolchain)
            end
        end

        llvm_dirs = {root = rootdir,
        	           bin = bindir,
        	           lib = libdir,
        	           cxxlib = cxxlibdir,
        	           include = includedir,
        	           cxxinclude = cxxincludedir,
        	           res = resdir,
        	           rt = rtdir,
        	           rtlink = rtlink }
        _g.llvm_dirs = llvm_dirs
      end
      return llvm_dirs
end
