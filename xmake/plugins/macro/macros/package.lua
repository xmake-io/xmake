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
,   {nil, "target",     "v",   nil,         "The target name. It will package all default targets if this parameter is not specified."}
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

    -- package all archs
    local plat = args.plat
    local archs = args.arch and args.arch:split(',') or platform.archs(plat)
    for _, arch in ipairs(archs) do
        local argv = {"f", "-cy", "-p", plat, "-a", arch}
        if args.config then
            table.join2(argv, os.argv(args.config))
        end
        if option.get("verbose") then
            table.insert(argv, "-v")
        end
        if option.get("diagnosis") then
            table.insert(argv, "-D")
        end
        os.execv(os.programfile(), argv)
        argv = {"p", "-f", "oldpkg"}
        if args.outputdir then
            table.insert(argv, "-o")
            table.insert(argv, args.outputdir)
        end
        if option.get("verbose") then
            table.insert(argv, "-v")
        end
        if option.get("diagnosis") then
            table.insert(argv, "-D")
        end
        if option.get("target") then
            table.insert(argv, option.get("target"))
        end
        os.execv(os.programfile(), argv)
    end

    -- package universal for iphoneos, watchos ...
    if plat == "iphoneos" or plat == "watchos" or plat == "macosx" then

        config.load()
        os.cd(project.directory())

        local outputdir = args.outputdir or config.get("buildir")
        local targets = {}
        if option.get("target") then
            local target = project.target(option.get("target"))
            if target then
                table.insert(targets, target)
            end
        else
            for _, target in pairs(project.targets()) do
                table.insert(targets, target)
            end
        end
        for _, target in ipairs(targets) do
            local modes = {}
            for _, modedir in ipairs(os.dirs(format("%s/%s.pkg/*/*/lib/*", outputdir, target:name()))) do
                table.insert(modes, path.basename(modedir))
            end
            for _, mode in ipairs(table.unique(modes)) do
                local lipoargs = nil
                for _, arch in ipairs(archs) do
                    local archfile = format("%s/%s.pkg/%s/%s/lib/%s/%s", outputdir, target:name(), plat, arch:trim(), mode, path.filename(target:targetfile()))
                    if os.isfile(archfile) then
                        lipoargs = format("%s -arch %s %s", lipoargs or "", arch, archfile)
                    end
                end
                if lipoargs then
                    lipoargs = format("-create %s -output %s/%s.pkg/%s/universal/lib/%s/%s", lipoargs, outputdir, target:name(), plat, mode, path.filename(target:targetfile()))
                    os.mkdir(format("%s/%s.pkg/%s/universal/lib/%s", outputdir, target:name(), plat, mode))
                    os.execv(os.programfile(), {"l", "lipo", lipoargs})
                end
            end
        end
    end
end
