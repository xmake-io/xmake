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

rule("xcode.metal")

    -- support add_files("*.metal")
    set_extensions(".metal")

    on_load(function (target)
        local cross
        if target:is_plat("macosx") then
            cross = "xcrun -sdk macosx "
        elseif target:is_plat("iphoneos") then
            cross = target:is_arch("i386", "x86_64") and "xcrun -sdk iphonesimulator " or "xcrun -sdk iphoneos "
        elseif target:is_plat("watchos") then
            cross = target:is_arch("i386") and "xcrun -sdk watchsimulator " or "xcrun -sdk watchos "
        elseif target:is_plat("appletvos") then
            cross = target:is_arch("i386", "x86_64") and "xcrun -sdk appletvsimulator " or "xcrun -sdk appletvos "
        else
            raise("unknown platform for xcode!")
        end
        target:data_set("xcode.metal.cross", cross)
    end)

    -- build *.metal to *.air
    on_buildcmd_file(function (target, batchcmds, sourcefile, opt)

        -- get metal
        import("lib.detect.find_tool")
        local cross = target:data("xcode.metal.cross")
        local metal = assert(find_tool("metal", {program = cross .. " metal"}), "metal command not found!")

        -- add objectfile (.air)
        local objectfile = target:objectfile(sourcefile) .. ".air"

        -- add commands
        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.metal %s", sourcefile)
        batchcmds:mkdir(path.directory(objectfile))
        batchcmds:vrunv(metal.program, {"-c", "-o", objectfile, sourcefile})

        -- add deps
        batchcmds:add_depfiles(sourcefile)
        batchcmds:set_depmtime(os.mtime(objectfile))
        batchcmds:set_depcache(target:dependfile(objectfile))

    end)

    -- link *.air to *.metallib
    on_linkcmd(function (target, batchcmds, opt)
        print("linkcmd")
    end)
