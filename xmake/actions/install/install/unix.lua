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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        unix.lua
--

-- install library
function _install_library(target)

    -- install libraries
    local librarydir = path.join(target:installdir(), "lib")
    os.mkdir(librarydir)
    os.vcp(target:targetfile(), librarydir)

    -- install headers 
    local includedir = path.join(target:installdir(), "include")
    os.mkdir(includedir)
    local srcheaders, dstheaders = target:headerfiles(includedir)
    if srcheaders and dstheaders then
        local i = 1
        for _, srcheader in ipairs(srcheaders) do
            local dstheader = dstheaders[i]
            if dstheader then
                os.vcp(srcheader, dstheader)
            end
            i = i + 1
        end
    end
end

-- install binary
function install_binary(target)
    local binarydir = path.join(target:installdir(), "bin")
    os.mkdir(binarydir)
    os.vcp(target:targetfile(), binarydir)
end

-- install shared library
function install_shared(target)
    _install_library(target)
end

-- install static library
function install_shared(target)
    _install_library(target)
end
