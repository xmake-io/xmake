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
-- @file        install.lua
--

-- imports
import("core.base.option")

-- get menu options
function menu_options()

    -- description
    local description = "Install the given packages."

    -- menu options
    local options =
    {
        {'k', "kind",          "kv", nil, "Enable static/shared library.",
                                       values = {"static", "shared"}         },
        {'p', "plat",          "kv", nil, "Set the given platform."          },
        {'a', "arch",          "kv", nil, "Set the given architecture."      },
        {'m', "mode",          "kv", nil, "Set the given mode.",
                                       values = {"release", "debug"}         },
        {'f', "configs",       "kv", nil, "Set the given extra package configs.",
                                       "e.g.",
                                       "    - xrepo install -f \"vs_runtime='MD'\" zlib",
                                       "    - xrepo install -f \"regex=true,thread=true\" boost"},
        {'j', "jobs",          "kv", tostring(os.default_njob()),
                                          "Set the number of parallel compilation jobs."},
        {nil, "linkjobs",      "kv", nil,    "Set the number of parallel link jobs."},
        {nil, "includes",      "kv", nil, "Includes extra lua configuration files.",
                                       "e.g.",
                                       "    - xrepo install -p cross --toolchain=mytool --includes='toolchain1.lua" .. path.envsep() .. "toolchain2.lua'"},
        {category = "Visual Studio SDK Configuration"                        },
        {nil, "vs",            "kv", nil, "The Microsoft Visual Studio"
                                        , "  e.g. --vs=2017"                 },
        {nil, "vs_toolset",    "kv", nil, "The Microsoft Visual Studio Toolset Version"
                                        , "  e.g. --vs_toolset=14.0"         },
        {nil, "vs_sdkver",     "kv", nil, "The Windows SDK Version of Visual Studio"
                                        , "  e.g. --vs_sdkver=10.0.15063.0"  },
        {category = "Android NDK Configuration"                              },
        {nil, "ndk",           "kv", nil, "Set the android NDK directory."   },
        {category = "Cross Compilation Configuration"                        },
        {nil, "sdk",           "kv", nil, "Set the SDK directory of cross toolchain." },
        {nil, "toolchain",     "kv", nil, "Set the toolchain name."          },
        {category = "MingW Configuration"                                    },
        {nil, "mingw",         "kv", nil, "Set the MingW SDK directory."     },
        {category = "XCode SDK Configuration"                                },
        {nil, "xcode",         "kv", nil, "The Xcode Application Directory"  },
        {nil, "xcode_sdkver",  "kv", nil, "The SDK Version for Xcode"        },
        {nil, "target_minver", "kv", nil, "The Target Minimal Version"       },
        {category = "Other Configuration"                                    },
        {nil, "force",         "k",  nil, "Force to reinstall all package dependencies."},
        {nil, "shallow",       "k",  nil, "Does not install dependent packages."},
        {nil, "build",         "k",  nil, "Always build and install packages from source."},
        {},
        {nil, "packages",      "vs", nil, "The packages list.",
                                       "e.g.",
                                       "    - xrepo install zlib boost",
                                       "    - xrepo install /tmp/zlib.lua",
                                       "    - xrepo install -p iphoneos -a arm64 \"zlib >=1.2.0\"",
                                       "    - xrepo install -p android [--ndk=/xxx] -m debug \"pcre2 10.x\"",
                                       "    - xrepo install -p mingw [--mingw=/xxx] -k shared zlib",
                                       "    - xrepo install conan::zlib/1.2.11 vcpkg::zlib"}
    }

    -- show menu options
    local function show_options()

        -- show usage
        cprint("${bright}Usage: $${clear cyan}xrepo install [options] packages")

        -- show description
        print("")
        print(description)

        -- show options
        option.show_options(options, "install")
    end
    return options, show_options, description
end

-- install packages
function _install_packages(packages)

    -- enter working project directory
    local workdir = path.join(os.tmpdir(), "xrepo", "working")
    if not os.isdir(workdir) then
        os.mkdir(workdir)
        old_dir = os.cd(workdir)
        os.vrunv("xmake", {"create", "-P", "."})
    else
        old_dir = os.cd(workdir)
    end

    -- is package configuration file? e.g. xrepo install xxx.lua
    --
    -- xxx.lua
    --   add_requires("libpng", {system = false})
    --   add_requireconfs("libpng.*", {configs = {shared = true}})
    local filemode = false
    if type(packages) == "string" or #packages == 1 then
        local packagefile = table.unwrap(packages)
        if not packagefile:startswith("/") then
            packagefile = path.join(old_dir, packagefile)
        end
        if type(packagefile) == "string" and packagefile:endswith(".lua") and os.isfile(packagefile) then
            assert(os.isfile("xmake.lua"), "xmake.lua not found!")
            os.cp("xmake.lua", "xmake.lua.bak")
            os.cp(packagefile, "xmake.lua")
            filemode = true
        end
        if not filemode then
            if os.isfile("xmake.lua.bak") then
                os.cp("xmake.lua.bak", "xmake.lua")
            end
        end
    end

    -- disable xmake-stats
    os.setenv("XMAKE_STATS", "false")

    -- do configure first
    local config_argv = {"f", "-c"}
    if option.get("verbose") then
        table.insert(config_argv, "-v")
    end
    if option.get("diagnosis") then
        table.insert(config_argv, "-D")
    end
    if option.get("plat") then
        table.insert(config_argv, "-p")
        table.insert(config_argv, option.get("plat"))
    end
    if option.get("arch") then
        table.insert(config_argv, "-a")
        table.insert(config_argv, option.get("arch"))
    end
    local mode  = option.get("mode")
    if mode then
        table.insert(config_argv, "-m")
        table.insert(config_argv, mode)
    end
    local kind  = option.get("kind")
    if kind then
        table.insert(config_argv, "-k")
        table.insert(config_argv, kind)
    end
    -- for android
    if option.get("ndk") then
        table.insert(config_argv, "--ndk=" .. option.get("ndk"))
    end
    -- for cross toolchain
    if option.get("sdk") then
        table.insert(config_argv, "--sdk=" .. option.get("sdk"))
    end
    if option.get("toolchain") then
        table.insert(config_argv, "--toolchain=" .. option.get("toolchain"))
    end
    -- for mingw
    if option.get("mingw") then
        table.insert(config_argv, "--mingw=" .. option.get("mingw"))
    end
    -- for vs
    if option.get("vs") then
        table.insert(config_argv, "--vs=" .. option.get("vs"))
    end
    if option.get("vs_toolset") then
        table.insert(config_argv, "--vs_toolset=" .. option.get("vs_toolset"))
    end
    if option.get("vs_sdkver") then
        table.insert(config_argv, "--vs_sdkver=" .. option.get("vs_sdkver"))
    end
    -- for xcode
    if option.get("xcode") then
        table.insert(config_argv, "--xcode=" .. option.get("xcode"))
    end
    if option.get("xcode_sdkver") then
        table.insert(config_argv, "--xcode_sdkver=" .. option.get("xcode_sdkver"))
    end
    if option.get("target_minver") then
        table.insert(config_argv, "--target_minver=" .. option.get("target_minver"))
    end
    local envs = {XMAKE_RCFILES = option.get("includes")}
    os.vrunv("xmake", config_argv, {envs = envs})

    -- do install
    local require_argv = {"require"}
    if option.get("yes") then
        table.insert(require_argv, "-y")
    end
    if option.get("verbose") then
        table.insert(require_argv, "-v")
    end
    if option.get("diagnosis") then
        table.insert(require_argv, "-D")
    end
    if option.get("jobs") then
        table.insert(require_argv, "-j")
        table.insert(require_argv, option.get("jobs"))
    end
    if option.get("linkjobs") then
        table.insert(require_argv, "--linkjobs=" .. option.get("linkjobs"))
    end
    if option.get("force") then
        table.insert(require_argv, "--force")
    end
    if option.get("shallow") then
        table.insert(require_argv, "--shallow")
    end
    if option.get("build") then
        table.insert(require_argv, "--build")
    end
    local extra = {system = false}
    if mode == "debug" then
        extra.debug = true
    end
    if kind == "shared" then
        extra.configs = extra.configs or {}
        extra.configs.shared = true
    end
    local configs = option.get("configs")
    if configs then
        extra.system  = false
        extra.configs = extra.configs or {}
        local extra_configs, errors = ("{" .. configs .. "}"):deserialize()
        if extra_configs then
            table.join2(extra.configs, extra_configs)
        else
            raise(errors)
        end
    end
    if extra then
        local extra_str = string.serialize(extra, {indent = false, strip = true})
        table.insert(require_argv, "--extra=" .. extra_str)
    end
    if not filemode then
        table.join2(require_argv, packages)
    end
    os.vexecv("xmake", require_argv, {envs = envs})
end

-- main entry
function main()
    local packages = option.get("packages")
    if packages then
        _install_packages(packages)
    else
        raise("please specify the packages to be installed.")
    end
end
