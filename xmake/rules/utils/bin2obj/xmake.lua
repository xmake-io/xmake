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

rule("utils.bin2obj")
    set_extensions(".bin")
    add_orders("utils.bin2obj", "c++.build.modules.builder")
    on_buildcmd_file(function (target, batchcmds, sourcefile_bin, opt)

        -- get format (default: auto-detect from platform)
        local format = target:extraconf("rules", "utils.bin2obj", "format")
        if not format then
            if target:is_plat("windows", "mingw", "msys", "cygwin") then
                format = "coff"
            elseif target:is_plat("macosx", "iphoneos", "watchos", "appletvos") then
                format = "macho"
            else
                format = "elf"
            end
        end

        -- get object file (use .obj for COFF, .o for others)
        local objext = (format == "coff") and ".obj" or ".o"
        local objectfile = path.join(target:objectdir(), path.basename(sourcefile_bin) .. objext)
        table.insert(target:objectfiles(), objectfile)

        -- add commands
        batchcmds:show_progress(opt.progress, "${color.build.object}generating.bin2obj %s", sourcefile_bin)
        batchcmds:mkdir(path.directory(objectfile))

        -- get symbol prefix (default: _binary_)
        local symbol_prefix = target:extraconf("rules", "utils.bin2obj", "symbol_prefix") or "_binary_"

        -- get zeroend (default: false)
        -- check file-level config first, then rule-level config
        local fileconfig = target:fileconfig(sourcefile_bin)
        local zeroend = (fileconfig and fileconfig.zeroend) or target:extraconf("rules", "utils.bin2obj", "zeroend") or false

        -- get architecture
        local arch = target:arch()

        -- get platform
        local plat = target:plat()

        -- get target_minver and xcode_sdkver from xcode toolchain (if available)
        local target_minver = nil
        local xcode_sdkver = nil
        if format == "macho" then
            local toolchain = target:toolchain("xcode")
            if toolchain then
                target_minver = toolchain:config("target_minver")
                xcode_sdkver = toolchain:config("xcode_sdkver")
            end
        end

        -- convert binary file to object file
        local argv = {
            "-i", path(sourcefile_bin),
            "-o", path(objectfile),
            "-f", format,
            "-a", arch,
            "-p", plat
        }
        if symbol_prefix ~= "_binary_" then
            table.insert(argv, "--symbol_prefix=" .. symbol_prefix)
        end
        if target_minver then
            table.insert(argv, "--target_minver=" .. target_minver)
        end
        if xcode_sdkver then
            table.insert(argv, "--xcode_sdkver=" .. xcode_sdkver)
        end
        if zeroend then
            table.insert(argv, "--zeroend")
        end
        batchcmds:vlua("private.utils.bin2obj", argv)

        -- add deps
        batchcmds:add_depfiles(sourcefile_bin)
        batchcmds:set_depmtime(os.mtime(objectfile))
        batchcmds:set_depcache(target:dependfile(objectfile))
    end)
