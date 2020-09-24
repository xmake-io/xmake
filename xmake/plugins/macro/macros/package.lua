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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        package.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.platform.platform")

-- the options
local options =
{
    {'p', "plat",       "kv",  os.host(),   "Set the platform."                                    }
,   {'a', "arch",       "kv",  nil,         "Set the architectures. e.g. 'armv7, arm64'"           }
,   {'f', "config",     "kv",  nil,         "Pass the config arguments to \"xmake config\" .."     }
,   {'o', "outputdir",  "kv",  nil,         "Set the output directory of the package."             }
}

-- package all
--
-- e.g.
-- xmake m package
-- xmake m package -f "-m debug"
-- xmake m package -p linux
-- xmake m package -p iphoneos -f "-m debug --xxx ..." -o /tmp/xxx
-- xmake m package -f \"--mode=debug\"
--
function main(argv)

    -- parse arguments
    local args = option.parse(argv, options, "Package all architectures for the given the platform."
                                           , ""
                                           , "Usage: xmake macro package [options]")

    -- get platform
    local plat = args.plat

    -- get archs
    local archs = args.arch and args.arch:split(',') or platform.archs(plat)

    -- package all archs
    for _, arch in ipairs(archs) do

        -- config it
        os.exec("xmake f -p %s -a %s %s -c %s", plat, arch, args.config or "", option.get("verbose") and "-v" or "")

        -- package it
        if args.outputdir then
            os.exec("xmake p -o %s %s", args.outputdir, option.get("verbose") and "-v" or "")
        else
            os.exec("xmake p %s", option.get("verbose") and "-v" or "")
        end
    end

    -- package universal for iphoneos, watchos ...
    if plat == "iphoneos" or plat == "watchos" then

        -- load configure
        config.load()

        -- enter the project directory
        os.cd(project.directory())

        -- the outputdir directory
        local outputdir = args.outputdir or config.get("buildir")

        -- package all targets
        for _, target in pairs(project.targets()) do

            -- get all modes
            local modes = {}
            for _, modedir in ipairs(os.dirs(format("%s/%s.pkg/*/*/lib/*", outputdir, target:name()))) do
                table.insert(modes, path.basename(modedir))
            end
            for _, mode in ipairs(table.unique(modes)) do

                -- make lipo arguments
                local lipoargs = nil
                for _, arch in ipairs(archs) do
                    local archfile = format("%s/%s.pkg/%s/%s/lib/%s/%s", outputdir, target:name(), plat, arch:trim(), mode, path.filename(target:targetfile()))
                    if os.isfile(archfile) then
                        lipoargs = format("%s -arch %s %s", lipoargs or "", arch, archfile)
                    end
                end
                if lipoargs then

                    -- make full lipo arguments
                    lipoargs = format("-create %s -output %s/%s.pkg/%s/universal/lib/%s/%s", lipoargs, outputdir, target:name(), plat, mode, path.filename(target:targetfile()))

                    -- make universal directory
                    os.mkdir(format("%s/%s.pkg/%s/universal/lib/%s", outputdir, target:name(), plat, mode))

                    -- package all archs
                    os.execv("xmake", {"l", "lipo", lipoargs})
                end
            end
        end
    end
end
