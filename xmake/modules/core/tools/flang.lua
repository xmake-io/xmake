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
-- @file        flang.lua
--

-- inherit clang (flang is part of LLVM)
inherit("clang")
import("core.base.option")
import("core.language.language")

-- init it
function init(self)

    -- init super
    _super.init(self)

    -- init shflags
    self:set("fcshflags", "-shared")

    -- add -fPIC for shared
    if not self:is_plat("windows", "mingw") then
        self:add("fcshflags", "-fPIC")
        self:add("shared.fcflags", "-fPIC")
    end

    -- init flags map to filter unsupported C/C++ flags
    self:set("mapflags",
    {
        -- visibility flags (not supported by Fortran)
        ["-fvisibility=.*"] = "",
        -- strip flags (not supported by flang, use nf_strip instead)
        ["^-s$"] = ""
    })
end

-- make the strip flag
-- flang doesn't support -s directly, use -Wl,-s for linker
function nf_strip(self, level)
    local maps = {
        debug = "-Wl,-S"
    ,   all   = "-Wl,-s"
    }
    if self:is_plat("macosx", "iphoneos", "watchos", "appletvos", "applexros") then
        maps.all = {"-Wl,-x", "-Wl,-dead_strip"}
    elseif self:is_plat("windows") then
        -- flang doesn't support strip on windows
        maps = {}
    end
    return maps[level]
end

-- make the symbol flag
-- Fortran doesn't support visibility flags, only debug symbols
function nf_symbol(self, level)
    local kind = self:kind()
    if language.sourcekinds()[kind] then
        local maps = {
            debug = "-g"
        }
        return maps[level]
    elseif kind == "ld" or kind == "sh" then
        -- we need to add `-g` to linker to generate pdb symbol file for clang on windows
        if level == "debug" and self:is_plat("windows") then
            return "-g"
        end
    end
end

-- make the link arguments list
-- flang needs to pass install_name through -Wl, for macOS shared libraries
function linkargv(self, objectfiles, targetkind, targetfile, flags, opt)
    opt = opt or {}

    -- add install_name for macOS shared libraries
    local flags_extra = {}
    if targetkind == "shared" and self:is_plat("macosx", "iphoneos", "watchos") then
        -- check if install_name is already in flags
        local has_install_name = false
        for i, flag in ipairs(flags) do
            if flag == "-install_name" or flag:startswith("-Wl,-install_name") then
                has_install_name = true
                break
            end
        end
        if not has_install_name then
            table.insert(flags_extra, "-Wl,-install_name")
            table.insert(flags_extra, "-Wl,@rpath/" .. path.filename(targetfile))
        end
    end

    -- init arguments
    local argv = table.join("-o", targetfile, objectfiles, flags, flags_extra)
    if is_host("windows") and not opt.rawargs then
        argv = winos.cmdargv(argv, {escape = true})
    end
    return self:program(), argv
end

-- link the target file
--
-- maybe we need to use os.vrunv() to show link output when enable verbose information
-- @see https://github.com/xmake-io/xmake/discussions/2916
--
function link(self, objectfiles, targetkind, targetfile, flags, opt)
    opt = opt or {}

    -- enable linker output?
    local target = opt.target
    local linker_output = option.get("verbose")
    if linker_output == nil and target and target.policy and target:policy("build.linker.output") then
        linker_output = true
    end

    os.mkdir(path.directory(targetfile))

    local program, argv = linkargv(self, objectfiles, targetkind, targetfile, flags, opt)
    if linker_output then
        os.execv(program, argv, {envs = self:runenvs(), shell = opt.shell})
    else
        os.vrunv(program, argv, {envs = self:runenvs(), shell = opt.shell})
    end
end

