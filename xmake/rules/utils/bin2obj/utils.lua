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
-- @file        utils.lua
--

-- generate object file from binary file
--
-- @param target        the target
-- @param batchcmds     the batch commands
-- @param binaryfile    the binary file path
-- @param opt           the options
--                       - progress: the progress callback
--                       - format: the object file format (coff, elf, macho), auto-detected if not provided
--                       - symbol_prefix: the symbol prefix (default: _binary_)
--                       - zeroend: append null terminator (default: false)
--                       - rulename: the rule name for getting extra config (default: utils.bin2obj)
--                       - objectfile: the output object file path (optional, auto-generated if not provided)
--
function generate_objectfile(target, batchcmds, binaryfile, opt)
    opt = opt or {}
    local rulename = opt.rulename or "utils.bin2obj"
    local progress = opt.progress

    -- check for cosmocc toolchain
    local is_cosmocc = target:toolchain("cosmocc") or (target:has_tool("cc", "cosmocc") and target:has_tool("ar", "cosmoar"))

    -- get format (default: auto-detect from platform)
    local format = opt.format or target:extraconf("rules", rulename, "format")
    if not format then
        if is_cosmocc then
            format = "elf"
        elseif target:is_plat("windows", "mingw", "msys", "cygwin") then
            format = "coff"
        elseif target:is_plat("macosx", "iphoneos", "watchos", "appletvos") then
            format = "macho"
        else
            format = "elf"
        end
    end

    -- get object file
    local objectfile = opt.objectfile
    if not objectfile then
        objectfile = target:objectfile(binaryfile)
        -- adjust extension based on format (use .obj for COFF, .o for others)
        local objext = (format == "coff") and ".obj" or ".o"
        objectfile = objectfile:gsub("%.o$", objext):gsub("%.obj$", objext)
    end
    table.insert(target:objectfiles(), objectfile)

    -- add commands
    if progress then
        batchcmds:show_progress(progress, "${color.build.object}generating.bin2obj %s", binaryfile)
    end
    batchcmds:mkdir(path.directory(objectfile))

    -- get symbol prefix (default: _binary_)
    local symbol_prefix = opt.symbol_prefix or target:extraconf("rules", rulename, "symbol_prefix") or "_binary_"

    -- get zeroend (default: false, but can be overridden)
    local zeroend = opt.zeroend
    if zeroend == nil then
        zeroend = target:extraconf("rules", rulename, "zeroend") or false
    end

    -- get architecture and platform
    local arch = target:arch()
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
        "-i", path(binaryfile),
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
    batchcmds:vlua("cli.binutils.bin2obj", argv)

    -- generate concomitant object file for cosmocc
    if is_cosmocc then
        local arch_concomitant
        local objectfile_concomitant
        if arch == "x86_64" or arch == "x64" then
            arch_concomitant = "aarch64"
            objectfile_concomitant = path.join(path.directory(objectfile), ".aarch64", path.filename(objectfile))
        elseif arch == "aarch64" or arch == "arm64" then
            arch_concomitant = "x86_64"
            objectfile_concomitant = path.join(path.directory(objectfile), ".x86_64", path.filename(objectfile))
        end

        if arch_concomitant and objectfile_concomitant then
            batchcmds:mkdir(path.directory(objectfile_concomitant))
            local argv_concomitant = {
                "-i", path(binaryfile),
                "-o", path(objectfile_concomitant),
                "-f", format,
                "-a", arch_concomitant,
                "-p", plat
            }
            if symbol_prefix ~= "_binary_" then
                table.insert(argv_concomitant, "--symbol_prefix=" .. symbol_prefix)
            end
            if zeroend then
                table.insert(argv_concomitant, "--zeroend")
            end
            batchcmds:vlua("cli.binutils.bin2obj", argv_concomitant)
        end
    end

    return objectfile
end

