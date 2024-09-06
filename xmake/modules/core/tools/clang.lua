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
-- @author      ruki
-- @file        clang.lua
--

-- inherit gcc
inherit("gcc")
import("core.language.language")

-- init it
function init(self)

    -- init super
    _super.init(self)

    -- add cuflags
    if not self:is_plat("windows", "mingw") then
        self:add("shared.cuflags", "-fPIC")
    end

    -- suppress warning
    self:add("cxflags", "-Qunused-arguments")
    self:add("cuflags", "-Qunused-arguments")
    self:add("mxflags", "-Qunused-arguments")
    self:add("asflags", "-Qunused-arguments")

    -- add cuda path
    local cuda = get_config("cuda")
    if cuda then
        local cuda_path = "--cuda-path=" .. os.args(path.translate(cuda))
        self:add("cuflags", cuda_path)
    end

    -- init flags map
    self:set("mapflags",
    {
        -- warnings
        ["-W1"] = "-Wall"
    ,   ["-W2"] = "-Wall"
    ,   ["-W3"] = "-Wall"
    ,   ["-W4"] = "-Wall -Wextra"

         -- strip
    ,   ["-s"]  = "-s"
    ,   ["-S"]  = "-S"

        -- rdc
    ,   ["-rdc=true"] = "-fcuda-rdc"
    ,   ["-rdc true"] = "-fcuda-rdc"
    ,   ["--relocatable-device-code=true"] = "-fcuda-rdc"
    ,   ["--relocatable-device-code true"] = "-fcuda-rdc"
    ,   ["-rdc=false"] = ""
    ,   ["-rdc false"] = ""
    ,   ["--relocatable-device-code=false"] = ""
    ,   ["--relocatable-device-code false"] = ""
    })

end

-- make the fp-model flag
function nf_fpmodel(self, level)
    local maps
    if self:has_flags("-ffp-model=fast") then
        maps =
        {
            precise    = "-ffp-model=precise"
        ,   fast       = "-ffp-model=fast"
        ,   strict     = "-ffp-model=strict"
        ,   except     = "-ftrapping-math"
        ,   noexcept   = "-fno-trapping-math"
        }
    else
        maps =
        {
            precise    = "" -- default
        ,   fast       = "-ffast-math"
        ,   strict     = {"-frounding-math", "-ftrapping-math"}
        ,   except     = "-ftrapping-math"
        ,   noexcept   = "-fno-trapping-math"
        }
    end
    return maps[level]
end

-- make the optimize flag
function nf_optimize(self, level)
    -- only for source kind
    local kind = self:kind()
    if language.sourcekinds()[kind] then
        local maps =
        {
            none       = "-O0"
        ,   fast       = "-O1"
        ,   faster     = "-O2"
        ,   fastest    = "-O3"
        ,   smallest   = "-Oz" -- smaller than -Os
        ,   aggressive = "-Ofast"
        }
        return maps[level]
    end
end

-- make the warning flag
function nf_warning(self, level)
    local maps = {
        none       = "-w"
    ,   less       = "-Wall"
    ,   more       = "-Wall"
    ,   all        = "-Wall"
    ,   allextra   = {"-Wall", "-Wextra"}
    ,   extra      = "-Wextra"
    ,   pedantic   = "-Wpedantic"
    ,   everything = "-Weverything"
    ,   error      = "-Werror"
    }
    return maps[level]
end

-- make the symbol flag
function nf_symbol(self, level)
    local kind = self:kind()
    if kind == "ld" or kind == "sh" then
        -- clang/windows need add `-g` to linker to generate pdb symbol file
        if self:is_plat("windows") and level == "debug" then
            return "-g"
        end
    else
        return _super.nf_symbol(self, level)
    end
end

-- make the exception flag
--
-- e.g.
-- set_exceptions("cxx")
-- set_exceptions("objc")
-- set_exceptions("no-cxx")
-- set_exceptions("no-objc")
-- set_exceptions("cxx", "objc")
function nf_exception(self, exp)
    local maps = {
        cxx = "-fcxx-exceptions",
        ["no-cxx"] = "-fno-cxx-exceptions",
        objc = "-fobjc-exceptions",
        ["no-objc"] = "-fno-objc-exceptions"
    }
    local value = maps[exp]
    if value then
        return {exp:startswith("no-") and "-fno-exceptions" or "-fexceptions", value}
    end
end

-- has -fms-runtime-lib?
function _has_ms_runtime_lib(self)
    local has_ms_runtime_lib = _g._HAS_MS_RUNTIME_LIB
    if has_ms_runtime_lib == nil then
        if self:has_flags("-fms-runtime-lib=dll", "cxflags", {flagskey = "clang_ms_runtime_lib"}) then
            has_ms_runtime_lib = true
        end
        has_ms_runtime_lib = has_ms_runtime_lib or false
        _g._HAS_MS_RUNTIME_LIB = has_ms_runtime_lib
    end
    return has_ms_runtime_lib
end

-- has -static-libstdc++?
function _has_static_libstdcxx(self)
    local has_static_libstdcxx = _g._HAS_STATIC_LIBSTDCXX
    if has_static_libstdcxx == nil then
        if self:has_flags("-static-libstdc++ -Werror", "ldflags", {flagskey = "clang_static_libstdcxx"}) then
            has_static_libstdcxx = true
        end
        has_static_libstdcxx = has_static_libstdcxx or false
        _g._HAS_STATIC_LIBSTDCXX = has_static_libstdcxx
    end
    return has_static_libstdcxx
end

-- get llvm sdk root directory
function _get_llvm_rootdir(self)
    local llvm_rootdir = _g._LLVM_ROOTDIR
    if llvm_rootdir == nil then
        local outdata = try { function() return os.iorunv(self:program(), {"-print-resource-dir"}, {envs = self:runenvs()}) end }
        if outdata then
            llvm_rootdir = path.normalize(path.join(outdata:trim(), "..", "..", ".."))
            if not os.isdir(llvm_rootdir) then
                llvm_rootdir = nil
            end
        end
        _g._LLVM_ROOTDIR = llvm_rootdir or false
    end
    return llvm_rootdir or nil
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

-- make the runtime flag
-- @see https://github.com/xmake-io/xmake/issues/3546
function nf_runtime(self, runtime, opt)
    opt = opt or {}
    local maps
    -- if a sdk dir is defined, we should redirect include / library path to have the correct includes / libc++ link
    local kind = self:kind()
    if self:is_plat("windows") and runtime then
        if not _has_ms_runtime_lib(self) then
            if runtime:startswith("MD") then
                wprint("%s runtime is not available for the current Clang compiler.", runtime)
            end
            return
        end
        if language.sourcekinds()[kind] then
            maps = {
                MT  = "-fms-runtime-lib=static",
                MTd = "-fms-runtime-lib=static_dbg",
                MD  = "-fms-runtime-lib=dll",
                MDd = "-fms-runtime-lib=dll_dbg"
            }
        elseif kind == "ld" or kind == "sh" then
            maps = {
                MT  = "-nostdlib",
                MTd = "-nostdlib",
                MD  = "-nostdlib",
                MDd = "-nostdlib"
            }
        end
    end
    if not self:is_plat("android") then -- we will set runtimes in android ndk toolchain
        maps = maps or {}
        local llvm_rootdir = self:toolchain():sdkdir()
        if kind == "cxx" then
            maps["c++_static"]    = "-stdlib=libc++"
            maps["c++_shared"]    = "-stdlib=libc++"
            maps["stdc++_static"] = "-stdlib=libstdc++"
            maps["stdc++_shared"] = "-stdlib=libstdc++"
            if not llvm_rootdir and self:is_plat("windows") then
                -- clang on windows fail to add libc++ includepath when using -stdlib=libc++ so we manually add it
                -- @see https://github.com/llvm/llvm-project/issues/79647
                llvm_rootdir = _get_llvm_rootdir(self)
            end
            if llvm_rootdir then
                maps["c++_static"] = table.join(maps["c++_static"], "-cxx-isystem" .. path.join(llvm_rootdir, "include", "c++", "v1"))
                maps["c++_shared"] = table.join(maps["c++_shared"], "-cxx-isystem" .. path.join(llvm_rootdir, "include", "c++", "v1"))
            end
        elseif kind == "ld" or kind == "sh" then
            local target = opt.target or opt
            local is_cxx = target and (target.sourcekinds and table.contains(table.wrap(target:sourcekinds()), "cxx"))
            if is_cxx then
                maps["c++_static"]    = "-stdlib=libc++"
                maps["c++_shared"]    = "-stdlib=libc++"
                maps["stdc++_static"] = "-stdlib=libstdc++"
                maps["stdc++_shared"] = "-stdlib=libstdc++"
                if not llvm_rootdir and self:is_plat("windows") then
                    -- clang on windows fail to add libc++ librarypath when using -stdlib=libc++ so we manually add it
                    -- @see https://github.com/llvm/llvm-project/issues/79647
                    llvm_rootdir = _get_llvm_rootdir(self)
                end
                if llvm_rootdir then
                    local libdir = path.absolute(path.join(llvm_rootdir, "lib"))
                    maps["c++_static"] = table.join(maps["c++_static"], "-L" .. libdir)
                    maps["c++_shared"] = table.join(maps["c++_shared"], "-L" .. libdir)
                    -- sometimes llvm runtimes are located in a target-triple subfolder
                    local target_triple = _get_llvm_target_triple(self)
                    local triple_libdir = (target_triple and os.isdir(path.join(libdir, target_triple))) and path.join(libdir, target_triple)
                    if triple_libdir then
                        maps["c++_static"] = table.join(maps["c++_static"], "-L" .. triple_libdir)
                        maps["c++_shared"] = table.join(maps["c++_shared"], "-L" .. triple_libdir)
                    end
                    -- add rpath to avoid the user need to set LD_LIBRARY_PATH by hand
                    maps["c++_shared"] = table.join(maps["c++_shared"], nf_rpathdir(self, libdir))
                    if triple_libdir then
                        maps["c++_shared"] = table.join(maps["c++_shared"], nf_rpathdir(self, triple_libdir))
                    end
                    if target.is_shared and target:is_shared() and target.filename and self:is_plat("macosx", "iphoneos", "watchos") then
                        maps["c++_shared"] = table.join(maps["c++_shared"], "-install_name")
                        maps["c++_shared"] = table.join(maps["c++_shared"], "@rpath/" .. target:filename())
                    end
                end
                if runtime:endswith("_static") and _has_static_libstdcxx(self) then
                    maps["c++_static"] = table.join(maps["c++_static"], "-static-libstdc++")
                    maps["stdc++_static"] = table.join(maps["stdc++_static"], "-static-libstdc++")
                end
            end
        end
    end
    return maps and maps[runtime]
end
