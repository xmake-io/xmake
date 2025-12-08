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

-- generate header file from binary file
--
-- @param target        the target
-- @param batchcmds     the batch commands
-- @param binaryfile    the binary file path
-- @param opt           the options
--                       - progress: the progress callback
--                       - linewidth: the line width for output (optional)
--                       - nozeroend: disable null terminator (deprecated, for backward compatibility only)
--                       - zeroend: enable null terminator (default: true, bin2c enables zeroend by default for compatibility)
--                       - rulename: the rule name for getting extra config (default: utils.bin2c)
--                       - headerfile: the output header file path (optional, auto-generated if not provided)
--                       - headerdir: the header directory (optional, auto-generated if not provided)
--
function generate_headerfile(target, batchcmds, binaryfile, opt)
    opt = opt or {}
    local rulename = opt.rulename or "utils.bin2c"
    local progress = opt.progress

    -- get header directory and file
    local headerdir = opt.headerdir
    local headerfile = opt.headerfile
    if not headerfile then
        if not headerdir then
            headerdir = path.join(target:autogendir(), "rules", "utils", "bin2c")
        end
        headerfile = path.join(headerdir, path.filename(binaryfile) .. ".h")
    else
        headerdir = headerdir or path.directory(headerfile)
    end

    -- add includedirs
    target:add("includedirs", headerdir)

    -- add commands
    if progress then
        batchcmds:show_progress(progress, "${color.build.object}generating.bin2c %s", binaryfile)
    end
    batchcmds:mkdir(headerdir)

    -- build argv
    local argv = {"-i", path(binaryfile), "-o", path(headerfile)}

    -- get linewidth
    local linewidth = opt.linewidth or target:extraconf("rules", rulename, "linewidth")
    if linewidth then
        table.insert(argv, "-w")
        table.insert(argv, tostring(linewidth))
    end

    -- get nozeroend/zeroend (check file-level config first, then rule-level config, then opt)
    local fileconfig = target:fileconfig(binaryfile)
    local nozeroend = nil
    if fileconfig then
        if fileconfig.nozeroend ~= nil then
            nozeroend = fileconfig.nozeroend
        elseif fileconfig.zeroend ~= nil then
            nozeroend = not fileconfig.zeroend
        end
    end
    if nozeroend == nil then
        nozeroend = target:extraconf("rules", rulename, "nozeroend") or false
    end
    -- also support zeroend in opt (inverse of nozeroend)
    if opt.zeroend ~= nil then
        nozeroend = not opt.zeroend
    elseif opt.nozeroend ~= nil then
        nozeroend = opt.nozeroend
    end
    if nozeroend then
        table.insert(argv, "--nozeroend")
    end

    batchcmds:vlua("utils.binary.bin2c", argv)

    return headerfile
end

