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

-- build metal files
--
-- @see https://developer.apple.com/documentation/metal/libraries/building_a_library_with_metal_s_command-line_tools
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
        import("core.tool.toolchain")
        import("lib.detect.find_tool")
        local cross = target:data("xcode.metal.cross")
        local metal = assert(find_tool("metal", {program = cross .. " metal"}), "metal command not found!")

        -- get xcode toolchain
        local xcode = toolchain.load("xcode", {plat = target:plat(), arch = target:arch()})
        local target_minver = xcode:config("target_minver")
        local xcode_sysroot = xcode:config("xcode_sysroot")

        -- init metal arguments
        local objectfile = target:objectfile(sourcefile) .. ".air"
        local argv = {"-c", "-ffast-math", "-gline-tables-only"}
        if target_minver then
            table.insert(argv, "-target")
            local airarch = target:is_arch("x86_64", "arm64") and "air64" or "air32"
            if target:is_plat("macosx") then
                table.insert(argv, airarch .. "-apple-macos" .. target_minver)
            elseif target:is_plat("iphoneos") then
                local airtarget = airarch .. "-apple-ios" .. target_minver
                if target:is_arch("x86_64", "i386") then
                    airtarget = airtarget .. "-simulator"
                end
                table.insert(argv, airtarget)
            elseif target:is_plat("watchos") then
                local airtarget = airarch .. "-apple-watchos" .. target_minver
                if target:is_arch("x86_64", "i386") then
                    airtarget = airtarget .. "-simulator"
                end
                table.insert(argv, airtarget)
            elseif target:is_plat("appletvos") then
                local airtarget = airarch .. "-apple-tvos" .. target_minver
                if target:is_arch("x86_64", "i386") then
                    airtarget = airtarget .. "-simulator"
                end
                table.insert(argv, airtarget)
            end
        end
        if xcode_sysroot then
            table.insert(argv, "-isysroot")
            table.insert(argv, path(xcode_sysroot))
        end
        table.insert(argv, "-o")
        table.insert(argv, path(objectfile))
        table.insert(argv, path(sourcefile))

        -- add commands
        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.metal %s", sourcefile)
        batchcmds:mkdir(path.directory(objectfile))
        batchcmds:vrunv(metal.program, argv)

        -- add deps
        batchcmds:add_depfiles(sourcefile)
        batchcmds:set_depmtime(os.mtime(objectfile))
        batchcmds:set_depcache(target:dependfile(objectfile))
    end)

    -- link *.air to *.metallib
    before_linkcmd(function (target, batchcmds, opt)

        -- get objectfiles
        local objectfiles = {}
        local objectfiles_wrap = {}
        for rulename, sourcebatch in pairs(target:sourcebatches()) do
            if rulename == "xcode.metal" then
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    table.insert(objectfiles, target:objectfile(sourcefile) .. ".air")
                    table.insert(objectfiles_wrap, path(target:objectfile(sourcefile) .. ".air"))
                end
                break
            end
        end
        if #objectfiles == 0 then
            return
        end

        -- get metallib
        import("core.tool.toolchain")
        import("lib.detect.find_tool")
        local cross = target:data("xcode.metal.cross")
        local metallib = assert(find_tool("metallib", {program = cross .. " metallib"}), "metallib command not found!")

        -- get xcode toolchain
        local xcode = toolchain.load("xcode", {plat = target:plat(), arch = target:arch()})
        local xcode_sysroot = xcode:config("xcode_sysroot")

        -- add commands
        local resourcesdir = path.absolute(target:data("xcode.bundle.resourcesdir"))
        local libraryfile = resourcesdir and path.join(resourcesdir, "default.metallib") or (target:targetfile() .. ".metallib")
        batchcmds:show_progress(opt.progress, "${color.build.target}linking.metal %s", path.filename(libraryfile))
        batchcmds:mkdir(path.directory(libraryfile))
        batchcmds:vrunv(metallib.program, table.join({"-o", path(libraryfile)}, objectfiles_wrap), {envs = {SDKROOT = xcode_sysroot}})

        -- add deps
        batchcmds:add_depfiles(objectfiles)
        batchcmds:set_depmtime(os.mtime(libraryfile))
        batchcmds:set_depcache(target:dependfile(libraryfile))
    end)
