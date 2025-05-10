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
-- @file        policy.lua
--

-- define module: policy
local policy  = policy or {}

-- load modules
local os      = require("base/os")
local io      = require("base/io")
local path    = require("base/path")
local table   = require("base/table")
local utils   = require("base/utils")
local string  = require("base/string")

-- get all defined policies
function policy.policies()
    local policies = policy._POLICIES
    if not policies then
        policies = {
            -- We will check and ignore all unsupported flags by default, but we can also pass `{force = true}` to force to set flags, e.g. add_ldflags("-static", {force = true})
            ["check.auto_ignore_flags"]           = {description = "Enable check and ignore unsupported flags automatically.", default = true, type = "boolean"},
            -- We will map gcc flags to the current compiler and linker by default.
            ["check.auto_map_flags"]              = {description = "Enable map gcc flags to the current compiler and linker automatically.", default = true, type = "boolean"},
            -- We will check the compatibility of target and package licenses
            ["check.target_package_licenses"]     = {description = "Enable check the compatibility of target and package licenses.", default = true, type = "boolean"},
            -- Generate intermediate build directory
            ["build.intermediate_directory"]      = {description = "Generate intermediate build directory.", default = true, type = "boolean"},
            -- Provide a way to block all targets build that depends on self
            ["build.fence"]                       = {description = "Block all targets build that depends on self.", default = false, type = "boolean"},
            -- We can compile the source files for each target in parallel
            ["build.across_targets_in_parallel"]  = {description = "Enable compile the source files for each target in parallel.", default = true, type = "boolean"},
            -- Merge archive intead of linking for all dependent targets
            ["build.merge_archive"]               = {description = "Enable merge archive intead of linking for all dependent targets.", default = false, type = "boolean"},
            -- C/C++ build cache
            ["build.ccache"]                      = {description = "Enable C/C++ build cache.", type = "boolean"},
            -- Use global storage if build.ccache is enabled
            ["build.ccache.global_storage"]       = {description = "Use global storge if build.ccache is enabled.", type = "boolean"},
            -- Always update configfiles when building
            ["build.always_update_configfiles"]   = {description = "Always update configfiles when building.", type = "boolean"},
            -- Enable build warning output, it's enabled by default.
            ["build.warning"]                     = {description = "Enable build warning output.", default = true, type = "boolean"},
            -- Enable LTO linker-time optimization for c/c++ building.
            ["build.optimization.lto"]            = {description = "Enable LTO linker-time optimization for c/c++ building.", type = "boolean"},
            -- Enable address sanitizer for c/c++ building.
            ["build.sanitizer.address"]           = {description = "Enable address sanitizer for c/c++ building.", type = "boolean"},
            -- Enable thread sanitizer for c/c++ building.
            ["build.sanitizer.thread"]            = {description = "Enable thread sanitizer for c/c++ building.", type = "boolean"},
            -- Enable memort sanitizer for c/c++ building.
            ["build.sanitizer.memory"]            = {description = "Enable memory sanitizer for c/c++ building.", type = "boolean"},
            -- Enable leak sanitizer for c/c++ building.
            ["build.sanitizer.leak"]              = {description = "Enable leak sanitizer for c/c++ building.", type = "boolean"},
            -- Enable undefined sanitizer for c/c++ building.
            ["build.sanitizer.undefined"]         = {description = "Enable undefined sanitizer for c/c++ building.", type = "boolean"},
            -- Enable build rpath
            ["build.rpath"]                       = {description = "Enable build rpath.", default = true, type = "boolean"},
            -- Enable C++ modules for C++ building, even if no .mpp is involved in the compilation
            ["build.c++.modules"]                 = {description = "Enable C++ modules for C++ building.", type = "boolean"},
            -- Enable two phase compilation for C++ modules if supported by the compiler
            ["build.c++.modules.two_phases"]      = {description = "Enable two phase compilation if supported.", default = true, type = "boolean"},
            -- Enable std module
            ["build.c++.modules.std"]             = {description = "Enable std modules.", default = true, type = "boolean"},
            -- Enable unreferenced and non-public named module culling
            ["build.c++.modules.culling"]         = {description = "Enable unrefereced and non-public named module culling.", default = true, type = "boolean"},
            -- Always reuse compiled module bmi file
            ["build.c++.modules.reuse"]           = {description = "Reuse compiled module artifacts if possible.", default = true, type = "boolean"},
            ["build.c++.modules.tryreuse"]        = {description = "Try to reuse compiled module if possible. (deprecated)", default = false, type = "boolean"},
            -- Disabled flag check when reusing modules
            ["build.c++.modules.reuse.nocheck"]   = {description = "Disable flag compatibility check when reusing modules.", default = false, type = "boolean"},
            -- If target will not reuse modules from target deps if defines are different
            ["build.c++.modules.reuse.strict"]          = {description = "Enable strict defines comparison when trying to reuse module.", default = false, type = "boolean"},
            ["build.c++.modules.tryreuse.discriminate_on_defines"] = {description = "Enable defines module reuse discrimination.", default = false, type = "boolean"},
            -- Force C++ modules fallback dependency scanner for all compilers
            ["build.c++.modules.fallbackscanner"]       = {description = "Force fallback module dependency scanner.", default = false, type = "boolean"},
            -- Force C++ modules fallback dependency scanner for clang
            ["build.c++.modules.clang.fallbackscanner"] = {description = "Force clang fallback module dependency scanner.", default = false, type = "boolean"},
            ["build.c++.clang.fallbackscanner"]         = {description = "Force clang fallback module dependency scanner. (deprecated)", default = false, type = "boolean"},
            -- Force C++ modules fallback dependency scanner for msvc
            ["build.c++.modules.msvc.fallbackscanner"]  = {description = "Force msvc fallback module dependency scanner.", default = false, type = "boolean"},
            ["build.c++.msvc.fallbackscanner"]          = {description = "Force msvc fallback module dependency scanner. (deprecated)", default = false, type = "boolean"},
            -- Force C++ modules fallback dependency scanner for gcc
            ["build.c++.modules.gcc.fallbackscanner"]   = {description = "Force gcc fallback module dependency scanner.", default = false, type = "boolean"},
            ["build.c++.gcc.fallbackscanner"]           = {description = "Force gcc fallback module dependency scanner. (deprecated)", default = false, type = "boolean"},
            -- Force to enable new cxx11 abi in C++ modules for gcc
            -- If in the future, gcc can support it well, we'll turn it on by default
            -- https://github.com/xmake-io/xmake/issues/3855
            ["build.c++.modules.gcc.cxx11abi"]    = {description = "Force to enable new cxx11 abi in C++ modules for gcc.", type = "boolean"},
            ["build.c++.gcc.modules.cxx11abi"]    = {description = "Force to enable new cxx11 abi in C++ modules for gcc. (deprecated)", type = "boolean", default = false},
            -- Set the default vs runtime, e.g. MT, MD
            ["build.c++.msvc.runtime"]            = {description = "Set the default vs runtime.", type = "string", values = {"MT", "MD"}},
            -- Enable cuda device link
            ["build.cuda.devlink"]                = {description = "Enable Cuda devlink.", type = "boolean"},
            -- Enable build jobgraph
            ["build.jobgraph"]                    = {description = "Enable build jobgraph.", default = true, type = "boolean"},
            -- Enable windows UAC and set level, e.g. invoker, admin, highest
            ["windows.manifest.uac"]              = {description = "Enable windows manifest UAC.", type = "string"},
            -- Enable ui access for windows UAC
            ["windows.manifest.uac.ui"]           = {description = "Enable ui access for windows UAC.", type = "boolean"},
            -- Automatically build before running
            ["run.autobuild"]                     = {description = "Automatically build before running.", type = "boolean"},
            -- Enable install rpath
            ["install.rpath"]                     = {description = "Enable install rpath.", default = true, type = "boolean"},
            -- Strip package libraries for installation
            ["install.strip_packagelibs"]         = {description = "Strip package libraries for installation.", default = true, type = "boolean"},
            -- Preprocessor configuration for ccache/distcc, we can disable linemarkers to speed up preprocess
            ["preprocessor.linemarkers"]          = {description = "Enable linemarkers for preprocessor.", default = true, type = "boolean"},
            -- Preprocessor configuration for ccache/distcc, we can disable it to avoid cache object file with __DATE__, __TIME__
            ["preprocessor.gcc.directives_only"]  = {description = "Enable -fdirectives-only for gcc preprocessor.", type = "boolean"},
            -- We need to enable longpaths when building target or installing package
            ["platform.longpaths"]                = {description = "Enable long paths when building target or installing package on windows.", default = false, type = "boolean"},
            -- Lock required packages
            ["package.requires_lock"]             = {description = "Enable xmake-requires.lock to lock required packages.", default = false, type = "boolean"},
            -- Enable the precompiled packages, it will be enabled by default
            ["package.precompiled"]               = {description = "Enable precompiled packages.", default = true, type = "boolean"},
            -- Only fetch packages on system
            ["package.fetch_only"]                = {description = "Only fetch packages on system.", type = "boolean"},
            -- Only install packages from remote
            ["package.install_only"]              = {description = "Only install packages from remote.", type = "boolean"},
            -- Always install packages every time
            ["package.install_always"]            = {description = "Always install packages every time.", type = "boolean"},
            -- Install packages in the local project folder
            ["package.install_locally"]           = {description = "Install packages in the local project folder.", default = false, type = "boolean"},
            -- Set custom headers when downloading package
            ["package.download.http_headers"]     = {description = "Set the custom http headers when downloading package."},
            -- Use includes as external header files? e.g. -isystem ..
            ["package.include_external_headers"]  = {description = "Use includes as external headers.", type = "boolean"},
            -- Inherit the configs from the external command arguments, e.g. toolchains, `xmake f --toolchain=`
            ["package.inherit_external_configs"]  = {description = "Inherit the configs from the external command arguments.", default = true, type = "boolean"},
            -- Set strict compatibility for package and it's all child packages. we can just set it in package().
            -- if true, then any updates to this package, such as buildhash changes due to version changes,
            -- will force all installed child packages to be recompiled and installed, @see https://github.com/xmake-io/xmake/issues/2719
            ["package.strict_compatibility"]      = {description = "Set strict compatibility for package and it's all child packages.", type = "boolean"},
            -- Set strict compatibility for package and it's all library dependencies. we can set it in package() and user project configuration.
            -- if true, then any updates to library dependencies, such as buildhash changes due to version changes,
            -- will force the installed packages to be recompiled and installed. @see https://github.com/xmake-io/xmake/issues/2719
            ["package.librarydeps.strict_compatibility"] = {description = "Set strict compatibility for package and it's all library dependencies.", type = "boolean"},
            -- Resolve package dependencies conflict automatically
            -- @see https://github.com/xmake-io/xmake/issues/5745
            ["package.resolve_depconflict"]       = {description = "Automatically resolve package dependencies conflict.", default = true, type = "boolean"},
            -- Synchronize add_requires configuration in toplevel to all package dependencies for this package
            -- @see https://github.com/xmake-io/xmake/issues/5745
            ["package.sync_requires_to_deps"]     = {description = "Synchronize requires configuration to all package dependencies.", default = false, type = "boolean"},
            -- Automatically passes dependency configuration for inner xmake package
            -- @see https://github.com/xmake-io/xmake/issues/3952
            ["package.xmake.pass_depconfs"]       = {description = "Automatically passes dependency configuration for inner xmake package", default = true, type = "boolean"},
            -- It will force cmake package use ninja for build
            ["package.cmake_generator.ninja"]     = {description = "Set cmake package use ninja for build", type = "boolean"},
            -- Enable msbuild MultiToolTask
            ["package.msbuild.multi_tool_task"]   = {description = "Enable msbuild MultiToolTask.", default = false, type = "boolean"},
            -- Merge all static libraries after installing package
            -- @see https://github.com/xmake-io/xmake/issues/5894
            ["package.merge_staticlibs"]          = {description = "Merge all static libraries after installing package", type = "boolean"},
            -- C/C++ build cache
            ["package.build.ccache"]              = {description = "Enable C/C++ package build cache.", default = false, type = "boolean"},
            -- Stop to test on the first failure
            ["test.stop_on_first_failure"]        = {description = "Stop to test on the first failure", default = false, type = "boolean"},
            -- Return zero as exit code on failure
            ["test.return_zero_on_failure"]       = {description = "Return zero as the exit code on failure", default = false, type = "boolean"},
            -- Show diagnosis info for checking build dependencies
            ["diagnosis.check_build_deps"]        = {description = "Show diagnosis info for checking build dependencies", default = false, type = "boolean"},
            -- Set the network mode, e.g. public/private
            --   private: it will disable fetch remote package repositories
            ["network.mode"]                      = {description = "Set the network mode", type = "string"},
            -- Set the compatibility version, e.g. 2.0, 3.0
            ["compatibility.version"]             = {description = "Set the compatibility version", type = "string", default = "3.0", values = {"2.0", "3.0"}}
        }
        policy._POLICIES = policies
    end
    return policies
end

-- set policy default value
function policy.set_default(name, value)
    local defined_policy = policy.policies()[name]
    if defined_policy then
        defined_policy.default = value
    else
        os.raise("unknown policy(%s)!", name)
    end
end

-- check policy value
function policy.check(name, value)
    local defined_policy = policy.policies()[name]
    if defined_policy then
        if value == nil then
            value = defined_policy.default
        else
            local valtype = type(value)
            if valtype ~= defined_policy.type then
                utils.warning("policy(%s): invalid value type(%s), it shound be '%s'!",
                    name, valtype, defined_policy.type)
            end
            if defined_policy.values then
                local found = false
                for _, policy_value in ipairs(defined_policy.values) do
                    if tostring(value) == tostring(policy_value) then
                        found = true
                        break
                    end
                end
                if not found then
                    local values = {}
                    for _, policy_value in ipairs(defined_policy.values) do
                        table.insert(values, tostring(policy_value))
                    end
                    utils.warning("policy(%s): invalid value(%s), please set value from {%s}.",
                        name, value, table.concat(values, ", "))
                end
            end
        end
        return value
    else
        os.raise("unknown policy(%s)!", name)
    end
end

-- return module: policy
return policy
