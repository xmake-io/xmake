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
-- @file        extractlib.lua
--

-- imports
import("core.base.option")
import("core.base.binutils")

local options = {
    {'i', "libraryfile", "kv", nil,   "Set the static library file path (.a or .lib)."},
    {'o', "outputdir",   "kv", nil,   "Set the output directory to extract object files."}
}

function _do_extractlib(libraryfile, outputdir)
    -- init paths
    libraryfile = path.absolute(libraryfile)
    outputdir = path.absolute(outputdir)
    assert(os.isfile(libraryfile), "%s not found!", libraryfile)

    -- ensure output directory exists
    if not os.isdir(outputdir) then
        os.mkdir(outputdir)
    end

    -- trace
    print("extracting static library %s to %s ..", libraryfile, outputdir)

    -- do extraction
    local ok, errors = binutils.extractlib(libraryfile, outputdir)
    if not ok then
        raise("extractlib: %s", errors or "unknown error")
    end

    -- trace
    cprint("${bright}extraction completed!")
end

function main(...)
    -- parse arguments
    local argv = {...}
    local opt  = option.parse(argv, options, "Extract object files from static library (AR or MSVC lib format)."
                                                   , ""
                                                   , "Usage: xmake l utils.binary.extractlib [options]")

    -- do extractlib
    _do_extractlib(opt.libraryfile, opt.outputdir)
end

