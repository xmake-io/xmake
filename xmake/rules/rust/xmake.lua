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
-- @file        xmake.lua
--

-- generate bridge.rs.cc/h to call rust library in c++ code
-- @see https://cxx.rs/build/other.html
rule("rust.cxxbridge")
    set_extensions(".rsx")
    on_load(function (target)
        if not target:get("languages") then
            target:set("languages", "c++11")
        end
    end)
    before_buildcmd_file("build.cxxbridge")

rule("rust.build")
    set_sourcekinds("rc")
    on_load(function (target)
        -- set cratename
        local cratename = target:values("rust.cratename") or target:name()
        target:set("basename", cratename)
        -- set cratetype
        local cratetype = target:values("rust.cratetype")
        if cratetype == "staticlib" then
            assert(target:is_static(), "target(%s) must be static kind for cratetype(staticlib)!", target:name())
            target:add("arflags", "--crate-type=staticlib")
            target:data_set("inherit.links.exportlinks", false)
        elseif cratetype == "cdylib" then
            assert(target:is_shared(), "target(%s) must be shared kind for cratetype(cdylib)!", target:name())
            target:add("shflags", "--crate-type=cdylib", {force = true})
            target:add("shflags", "-C prefer-dynamic", {force = true})
        elseif target:is_static() then
            cratetype = "lib"
            target:set("values", "rust.cratetype", cratetype)
            if is_plat("windows") then
                target:set("prefixname", "lib")
            end
            target:set("extension", ".rlib")
            target:add("arflags", "--crate-type=" .. cratetype, {force = true})
            target:data_set("inherit.links.deplink", false)
        elseif target:is_shared() then
            cratetype = "dylib"
            target:set("values", "rust.cratetype", cratetype)
            target:add("shflags", "--crate-type=" .. cratetype, {force = true})
            -- fix cannot satisfy dependencies so `std` only shows up once
            -- https://github.com/rust-lang/rust/issues/19680
            --
            -- but it will link dynamic @rpath/libstd-xxx.dylib,
            -- so we can no longer modify and set other rpath paths
            target:add("shflags", "-C prefer-dynamic", {force = true})
            -- don't add links and instead use --extern CRATE[=PATH]
            -- also, it'll automatically link from linkdirs (-L) even if no --extern
            -- https://github.com/xmake-io/xmake/issues/6604
            target:data_set("inherit.links.deplink", false)
        elseif target:is_binary() then
            cratetype = "bin"
            target:set("values", "rust.cratetype", cratetype)
            target:add("ldflags", "--crate-type=" .. cratetype, {force = true})
        end

        -- set edition
        local edition = target:values("rust.edition") or "2018"
        target:add("rcflags", "--edition", edition, {force = true})

        -- set abort panic for no_std
        -- https://github.com/xmake-io/xmake/issues/4929
        local no_std = false
        local sourcebatch = target:sourcebatches()["rust.build"]
        if sourcebatch then
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                local content = io.readfile(sourcefile)
                if content and content:find("#![no_std]", 1, true) then
                    no_std = true
                    break
                end
            end
        end
        if no_std then
            target:add("rcflags", "-C panic=abort", {force = true})
        end
    end)
    on_build("build.target")

rule("rust")
    add_deps("rust.build")
    add_deps("utils.inherit.links")
