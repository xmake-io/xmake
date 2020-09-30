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

-- uninstall library
function _uninstall_library(target, opt)

    -- remove the target file
    local librarydir = path.join(target:installdir(), opt and opt.libdir or "lib")
    os.vrm(path.join(librarydir, path.filename(target:targetfile())))

    -- remove headers from the include directory
    local includedir = path.join(target:installdir(), opt and opt.includedir or "include")
    local _, dstheaders = target:headerfiles(includedir)
    for _, dstheader in ipairs(dstheaders) do
        os.vrm(dstheader)
    end
end

-- uninstall binary
function uninstall_binary(target, opt)
    local binarydir = path.join(target:installdir(), opt and opt.bindir or "bin")
    os.vrm(path.join(binarydir, path.filename(target:targetfile())))
end

-- uninstall shared library
function uninstall_shared(target, opt)
    _uninstall_library(target, opt)
end

-- uninstall static library
function uninstall_static(target, opt)
    _uninstall_library(target, opt)
end
