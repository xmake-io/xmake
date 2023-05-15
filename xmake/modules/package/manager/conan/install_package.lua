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

-- install package
--
-- @param name  the package name, e.g. conan::OpenSSL 1.0.2n
-- @param opt   the options, e.g. { verbose = true, mode = "release", plat = , arch = ,
--                                  configs = {
--                                      remote = "", build = "all", options = {}, imports = {}, build_requires = {},
--                                      settings = {"compiler=msvc", "compiler.version=10", "compiler.runtime=MD"}}}
--
function main(name, opt)
    local conan = find_tool("conan", {version = true})
    if not conan then
        raise("conan not found!")
    end
    if conan.version and semver.compare(conan.version, "2.0.5") >= 0 then
        -- https://github.com/conan-io/conan/issues/13709
        import("package.manager.conan.v2.install_package")(conan, name, opt)
    elseif conan.version and semver.compare(conan.version, "2.0.0") < 0 then
        import("package.manager.conan.v1.install_package")(conan, name, opt)
    else
        -- conan 2.0.0-2.0.4 does not supported
        raise("conan %s is not supported, please use conan 1.x", conan.version)
    end
end
