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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        install_package.lua
--

-- imports
import("core.base.option")
import("core.base.semver")
import("lib.detect.find_tool")

-- dotnet add package libpapki --version 1.0.147
function _install(dotnet, name, opt)

    -- init argv
    local argv = {"add", "package", name}
    local require_version = opt.require_version
    if require_version == "latest" then
        require_version = nil
    end
    if require_version then
        table.insert(argv, "--version")
        table.insert(argv, require_version)
    end

    local installdir = assert(opt.installdir, "installdir not found!")
    if not os.isdir(installdir) then
        os.mkdir(installdir)
    end
    local stubdir = path.join(installdir, "stub")
    if not os.isdir(stubdir) then
        os.vrunv(dotnet, {"new", "console", "-n", "stub"}, {curdir = installdir})
    end

    -- install package
    os.vrunv(dotnet, argv, {curdir = stubdir})
end

-- install package
--
-- @param name  the package name, e.g. pcre2
-- @param opt   the options, e.g. {verbose = true}
--
function main(name, opt)
    local dotnet = find_tool("dotnet")
    if not dotnet then
        raise("dotnet not found!")
    end
    _install(dotnet.program, name, opt or {})
end
