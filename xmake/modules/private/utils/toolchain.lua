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
function get_llvm_resourcedir(toolchain)
    local memcache = toolchain:memcache()
    local cachekey = "get_llvm_resourcedir"
    local llvm_resourcedir = memcache:get(cachekey)
    if llvm_resourcedir == nil then
        local cc = toolchain:tool("cc")
        if cc then
            local outdata = try { function() return os.iorunv(cc, {"-print-resource-dir"}) end }
            if outdata then
                llvm_resourcedir = path.normalize(outdata:trim())
                if not os.isdir(llvm_resourcedir) then
                    llvm_resourcedir = nil
                end
            end
        end
        memcache:set(cachekey, llvm_resourcedir or false)
    end
    return llvm_resourcedir or nil
end

-- get llvm sdk root directory
function get_llvm_rootdir(toolchain)
    local memcache = toolchain:memcache()
    local cachekey = "get_llvm_rootdir"
    local llvm_rootdir = memcache:get(cachekey)
    if llvm_rootdir == nil then
        local resourcedir = get_llvm_resourcedir(toolchain)
        if resourcedir then
            llvm_rootdir = path.normalize(path.join(resourcedir, "..", "..", ".."))
            if not os.isdir(llvm_rootdir) then
                llvm_rootdir = nil
            end
        end
        memcache:set(cachekey, llvm_rootdir or false)
    end
    return llvm_rootdir or nil
end

-- get compiler-rt info
function get_llvm_compiler_rtinfo(toolchain)
    local memcache = toolchain:memcache()
    local cachekey = "get_llvm_compiler_rtinfo"
    local rtinfo = memcache:get(cachekey)
    if rtinfo == nil then
        local resourcedir = get_llvm_resourcedir(toolchain)
        if resourcedir  then
            local res_libdir = path.join(resourcedir, "lib")
            -- when -DLLVM_ENABLE_TARGET_RUNTIME_DIR=OFF rtdir is windows/ and rtlink is clang_rt.builtins_<arch>.lib  
            -- when ON rtdir is windows/<target-triple> and rtlink is clang_rt.builtins.lib
            local target_triple = get_llvm_target_triple(toolchain)
            local arch = target_triple and target_triple:split("-")[1]

            local plat
            if toolchain:is_plat("windows", "mingw") then
                plat = "windows"
            elseif toolchain:is_plat("linux") then
                plat = "linux"
            elseif toolchain:is_plat("macosx", "iphoneos", "watchos", "appletvos", "applexros") then
                plat = "darwin"
            end
            
            local tripletdir = target_triple and path.join(res_libdir, "windows", target_triple)
            tripletdir = os.isdir(tripletdir) or nil

            local rtdir = tripletdir and path.join(plat, target_triple) or plat
            rtinfo = {rtdir = res_libdir, rtlibdir = path.join(res_libdir, rtdir)}
            if os.isdir(rtinfo.rtlibdir) and toolchain:is_plat("windows", "mingw") then
                local rtlink
                if tripletdir then
                    rtlink = "clang_rt.builtins.lib"
                elseif arch then
                    rtlink = "clang_rt.builtins-" .. arch .. ".lib"
                end
                if rtlink and os.isfile(path.join(rtinfo.rtlibdir, rtlink)) then
                    rtinfo.rtlink = path.join(rtdir, rtlink)
                end
            end
        end
        memcache:set(cachekey, rtinfo or false)
    end
    return rtinfo or nil
end

-- get llvm target triple
function get_llvm_target_triple(toolchain)
    local memcache = toolchain:memcache()
    local cachekey = "get_llvm_target_triple"
    local llvm_targettriple = memcache:get(cachekey)
    if llvm_targettriple == nil then
        local cc = toolchain:tool("cc")
        if cc then
            local outdata = try { function() return os.iorunv(cc, {"-print-target-triple"}) end }
            if outdata then
                llvm_targettriple = outdata:trim()
            end
        end
        memcache:set(cachekey, llvm_targettriple or false)
    end
    return llvm_targettriple or nil
end

-- get llvm toolchain dirs
function get_llvm_dirs(toolchain)
    local memcache = toolchain:memcache()
    local cachekey = "get_llvm_dirs"
    local llvm_dirs = memcache:get(cachekey)
    if llvm_dirs == nil then
        local rootdir = toolchain:sdkdir()
        if not rootdir and (toolchain:is_plat("windows") or is_host("windows")) then
            rootdir = get_llvm_rootdir(toolchain)
        end

        local bindir, libdir, cxxlibdir, includedir, cxxincludedir, resourcedir, rtdir, rtlink, rtlibdir
        if rootdir then
            bindir = path.join(rootdir, "bin")
            bindir = os.isdir(bindir) and bindir or nil

            libdir = path.join(rootdir, "lib")
            libdir = os.isdir(libdir) and libdir or nil

            if libdir then
                cxxlibdir = path.join(libdir, "c++")
                cxxlibdir = os.isdir(cxxlibdir) and cxxlibdir or nil
                if not cxxlibdir then
                    cxxlibdir = path.join(libdir, get_llvm_target_triple(toolchain))
                    cxxlibdir = os.isdir(cxxlibdir) and cxxlibdir or nil
                end
            end

            includedir = path.join(rootdir, "include")
            includedir = os.isdir(includedir) and includedir or nil

            if includedir then
                cxxincludedir = path.join(includedir, "c++", "v1")
                cxxincludedir = os.isdir(cxxincludedir) and cxxincludedir or nil
            end

            resourcedir = get_llvm_resourcedir(toolchain)
            local rtinfo = get_llvm_compiler_rtinfo(toolchain)
            if rtinfo then
                rtdir = rtinfo.rtdir
                rtlink = rtinfo.rtlink
                rtlibdir = rtinfo.rtlibdir
            end
        end

        llvm_dirs = {rootdir = rootdir,
                     bindir = bindir,
                     libdir = libdir,
                     cxxlibdir = cxxlibdir,
                     includedir = includedir,
                     cxxincludedir = cxxincludedir,
                     resourcedir = resourcedir,
                     rtdir = rtdir,
                     rtlibdir = rtlibdir,
                     rtlink = rtlink }
        memcache:set(cachekey, llvm_dirs)
      end
      return llvm_dirs
end

-- add runenvs for llvm
function add_llvm_runenvs(toolchain)
    local dirs = get_llvm_dirs(toolchain)
    if dirs then
        if dirs.bindir and (toolchain:is_plat("windows") or is_host("windows")) then
            toolchain:add("runenvs", "PATH", dirs.bindir)
        end
        for _, dir in ipairs({dirs.libdir or false, dirs.cxxlibdir or false, dirs.rtlibdir or false}) do
            if dir then
                if toolchain:is_plat("windows") or is_host("windows") then
                    toolchain:add("runenvs", "PATH", dir)
                elseif toolchain:is_plat("linux", "bsd") then
                    toolchain:add("runenvs", "LD_LIBRARY_PATH", dir)
                elseif toolchain:is_plat("macosx") then
                    -- using use DYLD_FALLBACK_LIBRARY_PATH instead of DYLD_LIBRARY_PATH to avoid symbols error when running homebrew llvm (which is linked to system libc++)
                    -- e.g dyld[5195]: Symbol not found: __ZnwmSt19__type_descriptor_t
                    -- Referenced from: <378C7CC2-7CD6-3B88-9C66-FE198E30462B> /usr/local/Cellar/llvm/21.1.5/bin/clang-21
                    -- Expected as weak-def export from some loaded dylibSymbol not found: __ZnamSt19__type_descriptor_t
                    toolchain:add("runenvs", "DYLD_FALLBACK_LIBRARY_PATH", dir)
                end
            end
        end
    end
end


