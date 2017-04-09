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
-- @file        installer.lua
--

-- imports
import("core.base.option")
import("core.platform.platform")

-- install binary
function install_binary_on_unix(target)

    -- check kind
    if not target:targetkind() then
        return 
    end

    -- the install directory
    local installdir = option.get("installdir") or platform.get("installdir")
    assert(installdir, "unknown install directory!")

    -- the binary directory
    local binarydir = path.join(installdir, "bin")

    -- make the binary directory
    os.mkdir(binarydir)

    -- copy the target file
    os.cp(target:targetfile(), binarydir)
end

-- install library
function install_library_on_unix(target)

    -- check kind
    if not target:targetkind() then
        return 
    end

    -- the install directory
    local installdir = option.get("installdir") or platform.get("installdir")
    assert(installdir, "unknown install directory!")

    -- the library directory
    local librarydir = path.join(installdir, "lib")

    -- the include directory
    local includedir = path.join(installdir, "include")

    -- make the library directory
    os.mkdir(librarydir)

    -- make the include directory
    os.mkdir(includedir)

    -- copy the target file
    os.cp(target:targetfile(), librarydir)

    -- copy the config.h to the include directory
    local configheader, configoutput = target:configheader(includedir)
    if configheader and configoutput then
        os.cp(configheader, configoutput) 
    end

    -- copy headers to the include directory
    local srcheaders, dstheaders = target:headerfiles(includedir)
    if srcheaders and dstheaders then
        local i = 1
        for _, srcheader in ipairs(srcheaders) do
            local dstheader = dstheaders[i]
            if dstheader then
                os.cp(srcheader, dstheader)
            end
            i = i + 1
        end
    end
end

-- uninstall binary
function uninstall_binary_on_unix(target)

    -- check kind
    if not target:targetkind() then
        return 
    end

    -- the install directory
    local installdir = option.get("installdir") or platform.get("installdir")
    assert(installdir, "unknown install directory!")

    -- the binary directory
    local binarydir = path.join(installdir, "bin")

    -- remove the target file
    os.rm(path.join(binarydir, path.filename(target:targetfile())))
end

-- uninstall library
function uninstall_library_on_unix(target)

    -- check kind
    if not target:targetkind() then
        return 
    end

    -- the install directory
    local installdir = option.get("installdir") or platform.get("installdir")
    assert(installdir, "unknown install directory!")

    -- the library directory
    local librarydir = path.join(installdir, "lib")

    -- the include directory
    local includedir = path.join(installdir, "include")

    -- remove the target file
    os.rm(path.join(librarydir, path.filename(target:targetfile())))

    -- reove the config.h from the include directory
    local _, configheader = target:configheader(includedir)
    if configheader then
        os.rm(configheader) 
    end

    -- remove headers from the include directory
    local _, dstheaders = target:headerfiles(includedir)
    for _, dstheader in ipairs(dstheaders) do
        os.rm(dstheader)
    end
end
