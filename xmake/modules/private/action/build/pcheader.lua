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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        pcheader.lua
--

-- imports
import("core.language.language")
import("object")

-- build the precompiled header file
function main(target, langkind, opt)

    -- get the precompiled header
    local pcheaderfile = target:pcheaderfile(langkind)
    if pcheaderfile then

        -- init sourcefile, objectfile and dependfile
        local sourcefile = pcheaderfile
        local objectfile = target:pcoutputfile(langkind)
        local dependfile = target:dependfile(objectfile)
        local sourcekind = language.langkinds()[langkind]

        -- init source batch
        local sourcebatch = {sourcekind = sourcekind, sourcefiles = {sourcefile}, objectfiles = {objectfile}, dependfiles = {dependfile}}

        -- build this precompiled header
        local progress = opt.progress
        if type(progress) == "number" then
            progress = {start = progress, stop = progress}
        end
        object(target, sourcebatch, {progress = progress})
    end
end
