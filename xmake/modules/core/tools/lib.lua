--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        lib.lua
--

-- get the property
function get(self, name)

    -- get it
    return _g[name]
end

-- extract the static library to object directory
function extract(self, libraryfile, objectdir)

    -- make the object directory first
    os.mkdir(objectdir)

    -- list object files 
    local objectfiles = os.iorun("%s -nologo -list %s", self:program(), libraryfile)

    -- extrace all object files
    for _, objectfile in ipairs(objectfiles:split('\n')) do

        -- is object file?
        if objectfile:find("%.obj") then

            -- make the outputfile
            local outputfile = path.translate(format("%s\\%s", objectdir, path.filename(objectfile)))

            -- repeat? rename it
            if os.isfile(outputfile) then
                for i = 0, 10 do
                    outputfile = path.translate(format("%s\\%d_%s", objectdir, i, path.filename(objectfile)))
                    if not os.isfile(outputfile) then 
                        break
                    end
                end
            end

            -- extract it
            os.run("%s -nologo -extract:%s -out:%s %s", self:program(), objectfile, outputfile, libraryfile)
        end
    end
end


