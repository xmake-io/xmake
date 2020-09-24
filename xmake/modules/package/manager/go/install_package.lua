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
-- @file        install_package.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("lib.detect.find_tool")
import("core.package.package")
import("private.tools.go.goenv")

-- get the package cache directory
function _go_get_cachedir(name, opt)
    local name = "go_" .. name:lower()
    return path.join(package.cachedir(), name:sub(1, 1), name, opt.version)
end

-- get the package install directory
function _go_get_installdir(name, opt)
    local name = "go_" .. name:lower()
    local dir = path.join(package.installdir(), name:sub(1, 1):lower(), name)
    if opt.version then
        dir = path.join(dir, opt.version)
    end
    return path.join(dir, opt.buildhash)
end

-- install package
--
-- @param name  the package name, e.g. go::github.com/sirupsen/logrus
-- @param opt   the options, e.g. { verbose = true, mode = "release", plat = , arch = , version = "x.x.x", buildhash = "xxxxxx"}
--
-- @return      true or false
--
function main(name, opt)

    -- TODO we do not yet support the installation of go packages in specific versions
    local version = opt.version
    assert(not version or version == "latest" or version == "master", "we can only support to install go packages without version!")

    -- find go
    local go = find_tool("go")
    if not go then
        raise("go not found!")
    end

    -- get plat and arch
    local goos   = goenv.GOOS(opt.plat)
    local goarch = goenv.GOARCH(opt.arch)

    -- get go package to cachedir/pkg/${goos}_${goarch}/github.com/xxx/*.a
    local cachedir = _go_get_cachedir(name, opt)
    os.tryrm(cachedir)
    os.mkdir(cachedir)
    os.vrunv(go.program, {"get", "-u", name}, {envs = {GOPATH = cachedir, GOOS = goos, GOARCH = goarch}, curdir = cachedir})

    -- install go package
    local installdir = _go_get_installdir(name, opt)
    local pkgdir = path.join(cachedir, "pkg", goos .. "_" .. goarch)
    os.tryrm(installdir)
    os.mkdir(path.join(installdir, "lib"))
    os.vcp(path.join(pkgdir, "**.a"), path.join(installdir, "lib"), {rootdir = pkgdir})
end
