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
-- @file        target.lua
--

-- imports
import("core.base.option")
import("core.base.hashset")
import("core.project.config")
import("core.project.project")
import("utils.binary.deplibs", {alias = "get_depend_libraries"})

-- Is this target has these tools?
function has_tool(toolname, tools)
    if toolname then
        -- We need compatibility with gcc/g++, clang/clang++ for c++ compiler/linker
        -- @see https://github.com/xmake-io/xmake/issues/6852
        local trim_xx = false
        if toolname == "clangxx" or toolname == "gxx" then
            toolname = toolname:rtrim("xx")
            trim_xx = true
        end
        for _, v in ipairs(tools) do
            if trim_xx then
                v = v:rtrim("xx")
            end
            if v and toolname:find("^" .. v:gsub("%-", "%%-") .. "$") then
                return true
            end
        end
    end
    return false
end

-- does this flag belong to this tool?
-- @see https://github.com/xmake-io/xmake/issues/3022
--
-- e.g.
--
-- for all: add_cxxflags("-g")
-- only for clang: add_cxxflags("clang::-stdlib=libc++")
-- only for clang and multiple flags: add_cxxflags("-stdlib=libc++", "-DFOO", {tools = "clang"})
--
function flag_belong_to_tool(flag, toolinst, extraconf)
    local for_this_tool = true
    local flagconf = extraconf and extraconf[flag]
    if type(flag) == "string" and flag:find("::", 1, true) then
        for_this_tool = false
        local splitinfo = flag:split("::", {plain = true})
        local toolname = splitinfo[1]
        local realname = toolinst:name()
        -- We need compatibility with gcc/g++, clang/clang++ for c++ compiler/linker
        -- @see https://github.com/xmake-io/xmake/issues/6852
        if realname == "clangxx" or realname == "gxx" then
            toolname = toolname:rtrim("xx")
            realname = realname:rtrim("xx")
        end
        if toolname == realname then
            flag = splitinfo[2]
            for_this_tool = true
        end
    elseif flagconf and flagconf.tools then
        for_this_tool = has_tool(toolinst:name(), flagconf.tools)
    end
    if for_this_tool then
        return flag
    end
end

-- translate flags in tool
function translate_flags_in_tool(target, flagkind, flags)
    local extraconf = target:extraconf(flagkind)
    local sourcekind
    local linkerkind
    if flagkind == "cflags" then
        sourcekind = "cc"
    elseif flagkind == "cxxflags" or flagkind == "cxflags" then
        sourcekind = "cxx"
    elseif flagkind == "asflags" then
        sourcekind = "as"
    elseif flagkind == "cuflags" then
        sourcekind = "cu"
    elseif flagkind == "ldflags" or flagkind == "shflags" then
        -- pass
    else
        raise("unknown flag kind %s", flagkind)
    end
    local toolinst = sourcekind and target:compiler(sourcekind) or target:linker()

    -- does this flag belong to this tool?
    -- @see https://github.com/xmake-io/xmake/issues/3022
    --
    -- e.g.
    --
    -- for all: add_cxxflags("-g")
    -- only for clang: add_cxxflags("clang::-stdlib=libc++")
    -- only for clang and multiple flags: add_cxxflags("-stdlib=libc++", "-DFOO", {tools = "clang"})
    --
    local result = {}
    for _, flag in ipairs(flags) do
        flag = flag_belong_to_tool(flag, toolinst, extraconf)
        if flag then
            table.insert(result, flag)
        end
    end
    return result
end

-- get project targets
function get_project_targets()
    local selected_target = option.get("target")
    if selected_target then
        -- return table.wrap(project.target(selected_target))
        return { project.target(selected_target) }
    end
    return project.targets()
end

-- check target toolchains
function check_target_toolchains()
    -- check toolchains configuration for all target in the current project
    -- @note we must check targets after loading options
    for _, target in pairs(project.targets()) do
        if target:is_enabled() and (target:get("toolchains") or
                                    not target:is_plat(config.get("plat")) or
                                    not target:is_arch(config.get("arch"))) then

            -- check platform toolchains first
            -- `target/set_plat()` and target:toolchains() need it
            target:platform():check()

            -- check target toolchains next
            local target_toolchains = target:get("toolchains")
            if target_toolchains then
                target_toolchains = hashset.from(table.wrap(target_toolchains))
                for _, toolchain_inst in pairs(target:toolchains()) do
                    -- check toolchains for `target/set_toolchains()`
                    if not toolchain_inst:check() and target_toolchains:has(toolchain_inst:name()) then
                        raise("toolchain(\"%s\"): not found!", toolchain_inst:name())
                    end
                end
            end
        elseif not target:get("toolset") then
            -- we only abort it when we know that toolchains of platform and target do not found
            local toolchain_found
            for _, toolchain_inst in pairs(target:toolchains()) do
                if toolchain_inst:is_standalone() then
                    toolchain_found = true
                end
            end
            assert(toolchain_found, "target(%s): toolchain not found!", target:name())
        end
    end
end

-- config target
function config_target(target, opt)
    for _, rule in ipairs(table.wrap(target:orderules())) do
        local before_config = rule:script("config_before")
        if before_config then
            before_config(target, opt)
        end
    end

    for _, rule in ipairs(table.wrap(target:orderules())) do
        local on_config = rule:script("config")
        if on_config then
            on_config(target, opt)
        end
    end
    local on_config = target:script("config")
    if on_config then
        on_config(target, opt)
    end

    for _, rule in ipairs(table.wrap(target:orderules())) do
        local after_config = rule:script("config_after")
        if after_config then
            after_config(target, opt)
        end
    end
end

-- config targets
function config_targets(opt)
    opt = opt or {}
    for _, target in ipairs(table.wrap(project.ordertargets())) do
        if target:is_enabled() then
            config_target(target, opt)
        end
    end
end

function get_target_package_libfiles(target, opt)
    opt = opt or {}
    local libfiles = {}
    for _, pkg in ipairs(target:orderpkgs(opt)) do
        if pkg:enabled() and pkg:get("libfiles") then
            for _, libfile in ipairs(table.wrap(pkg:get("libfiles"))) do
                local filename = path.filename(libfile)
                if filename:endswith(".dll") or filename:endswith(".so") or filename:find("%.so[%.%d+]+$") or filename:endswith(".dylib") then
                    table.insert(libfiles, libfile)
                end
            end
        end
    end
    -- we can only reserve used libraries
    if project.policy("install.strip_packagelibs") then
        if target:is_binary() or target:is_shared() or opt.binaryfile then
            -- we need to get all deplibs, e.g. app -> libfoo.so -> libbar.so ...
            -- @see https://github.com/xmake-io/xmake/issues/5325#issuecomment-2242597732
            local deplibs = get_depend_libraries(opt.binaryfile or target:targetfile(), {
                plat = target:plat(), arch = target:arch(),
                recursive = true, resolve_path = true, resolve_hint_paths = libfiles})
            if deplibs then
                local depends = hashset.from(deplibs)
                table.remove_if(libfiles, function (_, libfile) return not depends:has(libfile) end)
            end
        end
    end
    return libfiles
end

-- get target libraries
function get_target_libfiles(target, libfiles, binaryfile, refs, opt)
    if not refs[target] then
        local plaindeps = target:get("deps")
        if plaindeps then
            for _, depname in ipairs(plaindeps) do
                local dep = target:dep(depname)
                if dep then
                    if dep:is_shared() then
                        local depfile = dep:targetfile()
                        if os.isfile(depfile) then
                            table.insert(libfiles, depfile)
                        end
                        get_target_libfiles(dep, libfiles, dep:targetfile(), refs, opt)
                    elseif dep:is_library() then
                        get_target_libfiles(dep, libfiles, binaryfile, refs, opt)
                    end
                end
            end
        end
        table.join2(libfiles, get_target_package_libfiles(target, table.join({binaryfile = binaryfile}, opt)))
        refs[target] = true
    end
end




