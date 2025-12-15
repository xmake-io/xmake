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
-- @file        bin2obj.lua
--

-- imports
import("core.base.binutils")

function main(binarypath, outputpath, opt)
    -- init source directory and options
    opt = opt or {}
    binarypath = path.absolute(binarypath)
    outputpath = path.absolute(outputpath)
    assert(os.isfile(binarypath), "%s not found!", binarypath)

    -- get filename from binary path (with extension, dots replaced with underscores)
    local filename = path.filename(binarypath)
    -- replace dots with underscores for symbol name (e.g., data.bin -> data_bin)
    local basename = filename:gsub("%.", "_")
    opt.basename = basename

    -- validate format
    local format = opt.format
    if format then
        format = format:lower()
        if format ~= "coff" and format ~= "elf" and format ~= "macho" then
            raise("bin2obj: unsupported format '%s' (supported: coff, elf, macho)", format)
        end
    end

    -- trace
    print("converting binary file %s to %s object file %s ..", binarypath, format or "coff", outputpath)

    -- do conversion
    binutils.bin2obj(binarypath, outputpath, opt)

    -- generate concomitant object file for cosmocc
    if opt.cosmocc then
        local arch = opt.arch or "x86_64"
        local arch_concomitant
        local objectfile_concomitant
        if arch == "x86_64" or arch == "x64" then
            arch_concomitant = "aarch64"
            objectfile_concomitant = path.join(path.directory(outputpath), ".aarch64", path.filename(outputpath))
        elseif arch == "aarch64" or arch == "arm64" then
            arch_concomitant = "x86_64"
            objectfile_concomitant = path.join(path.directory(outputpath), ".x86_64", path.filename(outputpath))
        end

        if arch_concomitant and objectfile_concomitant then

            -- clone options for concomitant
            local opt_concomitant = table.clone(opt)
            opt_concomitant.arch = arch_concomitant
            opt_concomitant.cosmocc = false

            -- trace
            print("converting binary file %s to %s object file %s ..", binarypath, format or "coff", objectfile_concomitant)

            -- do conversion
            os.mkdir(path.directory(objectfile_concomitant))
            binutils.bin2obj(binarypath, objectfile_concomitant, opt_concomitant)
        end
    end

    -- trace
    cprint("${bright}%s generated!", outputpath)
end

