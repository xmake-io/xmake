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
-- @file        xmake.lua
--

function _plat_values(complete, opt)
    import("core.platform.platform")
    import("core.base.hashset")
    import("core.project.project")

    if not complete or not opt.arch then
        local plats = try {function () return project.allowed_plats() end}
        if plats then
            return plats:to_array()
        end
        return platform.plats()
    end

    -- arch has given, find all supported platforms
    local plats = {}
    for _, plat in ipairs(platform.plats()) do
        local archs = hashset.from(platform.archs(plat))
        if archs:has(opt.arch) then
            table.insert(plats, plat)
        end
    end
    return plats
end

function _arch_values(complete, opt)
    opt = opt or {}
    if opt.helpmenu then
        return
    end

    -- imports
    import("core.project.project")
    import("core.platform.platform")
    import("core.base.hashset")

    -- get all platforms
    local plats = try {function () return project.allowed_plats() end}
    if plats then
        plats = plats:to_array()
    end
    plats = plats or platform.plats()

    -- get all architectures
    local archset = hashset.new()
    for _, plat in ipairs(opt.plat and { opt.plat } or plats) do
        local archs = try {function () return project.allowed_archs(plat) end}
        if archs then
            archs = archs:to_array()
        end
        if not archs then
            archs = platform.archs(plat)
        end
        if archs then
            for _, arch in ipairs(archs) do
                archset:insert(arch)
            end
        end
    end
    return archset:to_array()
end

function _arch_description()
    import("core.project.project")
    import("core.platform.platform")

    -- get all platforms
    local plats = try {function () return project.allowed_plats() end}
    if plats then
        plats = plats:to_array()
    end
    plats = plats or platform.plats()

    -- get all architectures
    local description = {}
    for i, plat in ipairs(plats) do
        local archs = try {function () return project.allowed_archs(plat) end}
        if archs then
            archs = archs:to_array()
        end
        if not archs then
            archs = platform.archs(plat)
        end
        if archs and #archs > 0 then
            local desc = "    - " .. plat .. ":"
            for _, arch in ipairs(archs) do
                desc = desc .. " " .. arch
            end
            table.insert(description, desc)
        end
    end
    return description
end

function _mode_values(complete, opt)
    import("core.project.project")
    opt = opt or {}
    local modes = try {function()
        if opt.menuconf then
            -- we cannot load target.mode in menuconf
            local allowed_modes = project.allowed_modes()
            if allowed_modes then
                return allowed_modes:to_array()
            end
        else
            return project.modes()
        end
    end}
    if not modes then
        modes = {"debug", "release"}
    end
    return modes
end

function _target_values(complete, opt)
    return import("private.utils.complete_helper.targets")(complete, opt)
end

function _toolchain_values(complete, opt)
    if complete then
        import("core.tool.toolchain")
        return toolchain.list()
    end
end

function _project_menu_options()
    import("core.project.menu")
    return menu.options()
end

function _language_menu_options()
    import("core.language.menu")
    return menu.options("config")
end

function _platform_menu_options()
    import("core.platform.menu")
    return menu.options("config")
end

task("config")
    set_category("action")
    on_run("main")
    set_menu {
                usage = "xmake config|f [options] [target]",
                description = "Configure the project.",
                shortname = 'f',
                options = {
                    {'c', "clean",      "k",  nil       ,   "Clean the cached user configs and detection cache."},
                    {nil, "check",      "k",  nil       ,   "Just ignore detection cache and force to check all, it will reserve the cached user configs."},
                    {nil, "export",     "kv", nil       ,   "Export the current configuration to the given file."
                                                        ,   "    e.g."
                                                        ,   "    - xmake f -m debug -xxx=y --export=build/config.txt"},
                    {nil, "import",     "kv", nil       ,   "Import configs from the given file."
                                                        ,   "    e.g."
                                                        ,   "    - xmake f -import=build/config.txt"},
                    {nil, "menu",       "k",  nil       ,   "Configure project with a menu-driven user interface."},
                    {category = "."},
                    {'p', "plat",       "kv", "auto"    ,   "Compile for the given platform.", values = _plat_values},
                    {'a', "arch",       "kv", "auto"    ,   "Compile for the given architecture.", _arch_description, values = _arch_values},
                    {'m', "mode",       "kv", "auto" ,      "Compile for the given mode.", values = _mode_values},
                    {'k', "kind",       "kv", "static"  ,   "Compile for the given target kind.", values = {"static", "shared", "binary"}},
                    {nil, "host",       "kv", "$(host)" ,   "Set the current host environment."},
                    {nil, "policies",    "kv", nil       ,  "Set the project policies.",
                                                            "    e.g.",
                                                            "    - xmake f --policies=package.fetch_only",
                                                            "    - xmake f --policies=package.precompiled:n,package.install_only"},
                    {category = "Package Configuration"},
                    {nil, "require",    "kv",   nil     ,   "Require all dependent packages?", values = {"yes", "no"}},
                    {nil, "pkg_searchdirs", "kv", nil       , "The search directories of the remote package."
                                                            , "    e.g."
                                                            , "    - xmake f --pkg_searchdirs=/dir1" .. path.envsep() .. "/dir2"},
                    {category = "Cross Complation Configuration"},
                    {nil, "cross",      "kv", nil,          "Set cross toolchains prefix"
                                                          , "e.g."
                                                          , "    - i386-mingw32-"
                                                          , "    - arm-linux-androideabi-"},
                    {nil, "target_os",  "kv", nil,          "Set target os only for cross-complation"},
                    {nil, "bin",        "kv", nil,          "Set cross toolchains bin directory"
                                                          , "e.g."
                                                          , "    - sdk/bin (/arm-linux-gcc ..)"},
                    {nil, "sdk",        "kv", nil,          "Set cross SDK directory"
                                                          , "e.g."
                                                          , "    - sdk/bin"
                                                          , "    - sdk/lib"
                                                          , "    - sdk/include"},
                    {nil, "toolchain",  "kv", nil,          "Set toolchain name"
                                                          , "e.g. "
                                                          , "    - xmake f --toolchain=clang"
                                                          , "    - xmake f --toolchain=[cross|llvm|sdcc ..] --sdk=/xxx"
                                                          , "    - run `xmake show -l toolchains` to get all toolchains"
                                                          , values = _toolchain_values},
                    _language_menu_options,
                    _platform_menu_options,
                    {category = "Other Configuration"},
                    {nil, "debugger",   "kv", "auto"    , "Set debugger"},
                    {nil, "ccache",     "kv", true      , "Enable or disable the c/c++ compiler cache."},
                    {nil, "ccachedir",  "kv", nil       , "Set the ccache directory."},
                    {nil, "trybuild",   "kv", nil       , "Enable try-build mode and set the third-party buildsystem tool.",
                                                            "e.g.",
                                                            "    - xmake f --trybuild=auto; xmake",
                                                            "    - xmake f --trybuild=autoconf -p android --ndk=xxx; xmake",
                                                            "",
                                                            "the third-party buildsystems:"
                                                        ,   values = {"auto", "make", "autoconf", "cmake", "scons", "meson", "bazel", "ninja", "msbuild", "xcodebuild", "ndkbuild", "xrepo"}},
                    {nil, "tryconfigs", "kv", nil       ,   "Set the extra configurations of the third-party buildsystem for the try-build mode.",
                                                            "e.g.",
                                                            "    - xmake f --trybuild=autoconf --tryconfigs='--enable-shared=no'"},
                    {'o', "buildir",    "kv", "build"   , "Set build directory."},
                    {},
                    {nil, "target",     "v" , nil       , "Configure for the given target."
                                                        , values = _target_values},
                    {category = "Project Configuration"},
                    _project_menu_options}}



