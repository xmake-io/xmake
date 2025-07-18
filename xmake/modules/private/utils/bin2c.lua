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
-- @file        bin2c.lua
--

-- imports
import("core.base.bytes")
import("core.base.option")

local options = {
    {'w', "linewidth",  "kv", nil,   "Set the line width"},
    {nil, "nozeroend",  "k",  false, "Disable to patch zero terminating character"},
    {'i', "binarypath", "kv", nil,   "Set the binary file path."},
    {'o', "outputpath", "kv", nil,   "Set the output file path."}
}

function _do_dump(binarydata, outputfile, opt)
    local i = 0
    local n = 147
    local p = 0
    local e = binarydata:size()
    local line = nil
    local linewidth = opt.linewidth or 32
    local first = true
    while p < e do
        line = ""
        if p + linewidth <= e then
            for i = 0, linewidth - 1 do
                if first then
                    first = false
                    line = line .. " "
                else
                    line = line .. ","
                end
                line = line .. string.format(" 0x%02X", binarydata[p + i + 1])
            end
            outputfile:print(line)
            p = p + linewidth
        elseif p < e then
            local left = e - p
            for i = 0, left - 1 do
                if first then
                    first = false
                    line = line .. " "
                else
                    line = line .. ","
                end
                line = line .. string.format(" 0x%02X", binarydata[p + i + 1])
            end
            outputfile:print(line)
            p = p + left
        else
            break
        end
    end
end

function _do_bin2c(binarypath, outputpath, opt)

    -- init source directory and options
    opt = opt or {}
    binarypath = path.absolute(binarypath)
    outputpath = path.absolute(outputpath)
    assert(os.isfile(binarypath), "%s not found!", binarypath)

    -- trace
    print("generating code data file from %s ..", binarypath)

    -- optimize the default linewidth for reading large file
    if not opt.linewidth then
        local filesize = os.filesize(binarypath)
        if filesize > 1024 * 1024 * 1024 then
            opt.linewidth = 512
        elseif filesize > 100 * 1024 * 1024 then
            opt.linewidth = 256
        elseif filesize > 10 * 1024 * 1024 then
            opt.linewidth = 128
        elseif filesize > 1024 * 1024 then
            opt.linewidth = 64
        else
            opt.linewidth = 32
        end
    end

    -- do dump
    if utils.bin2c then
        utils.bin2c(binarypath, outputpath, opt)
    else
        local binarydata = bytes(io.readfile(binarypath, {encoding = "binary"}))
        local outputfile = io.open(outputpath, 'w')
        if outputfile then
            if not opt.nozeroend then
                binarydata = binarydata .. bytes('\0')
            end
            _do_dump(binarydata, outputfile, opt)
            outputfile:close()
        end
    end

    -- trace
    cprint("${bright}%s generated!", outputpath)
end

function main(...)

    -- parse arguments
    local argv = {...}
    local opt  = option.parse(argv, options, "Print c/c++ code files from the given binary file."
                                           , ""
                                           , "Usage: xmake l private.utils.bin2c [options]")

    -- do bin2c
    _do_bin2c(opt.binarypath, opt.outputpath, opt)
end
