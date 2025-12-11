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
import("core.base.binutils")

function main(libraryfile, outputdir)
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
    binutils.extractlib(libraryfile, outputdir)

    -- trace
    cprint("${bright}extraction completed!")
end

