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
-- @file        package.lua
--

-- concat packages, TODO components
function _concat_packages(a, b)
    local result = table.copy(a)
    for k, v in pairs(b) do
        local o = result[k]
        if o ~= nil then
            v = table.join(o, v)
        end
        result[k] = v
    end
    for k, v in pairs(result) do
        if k == "links" or k == "syslinks" or k == "frameworks" or k == "ldflags" or k == "shflags" then
            if type(v) == "table" and #v > 1 then
                -- we need to ensure link orders when removing repeat values
                v = table.reverse_unique(v)
            end
        elseif k == "static" or k == "shared" then
            v = table.unwrap(table.unique(v))
            if type(v) == "table" then
                -- conflict, {true, false}
                v = true
            end
        else
            v = table.unique(v)
        end
        result[k] = v
    end
    return result
end

-- set concat for find_package/fetch info
function fetchinfo_set_concat(fetchinfo)
    if fetchinfo and type(fetchinfo) == "table" then
        debug.setmetatable(fetchinfo, {__concat = _concat_packages})
    end
end

--
-- parse require string
--
-- basic
-- - add_requires("zlib")
--
-- semver
-- - add_requires("tbox >=1.5.1", "zlib >=1.2.11")
-- - add_requires("tbox", {version = ">=1.5.1"})
--
-- git branch/tag
-- - add_requires("zlib master")
--
-- with the given repository
-- - add_requires("xmake-repo@tbox >=1.5.1")
--
-- with the given configs
-- - add_requires("aaa_bbb_ccc >=1.5.1 <1.6.0", {optional = true, alias = "mypkg", debug = true})
-- - add_requires("tbox", {config = {coroutine = true, abc = "xxx"}})
--
-- with namespace and the 3rd package manager
-- - add_requires("xmake::xmake-repo@tbox >=1.5.1")
-- - add_requires("vcpkg::ffmpeg")
-- - add_requires("conan::OpenSSL/1.0.2n@conan/stable")
-- - add_requires("conan::openssl/1.1.1g") -- new
-- - add_requires("brew::pcre2/libpcre2-8 10.x", {alias = "pcre2"})
--
-- clone as a standalone package with the different configs
-- we can install and use these three packages at the same time.
-- - add_requires("zlib")
-- - add_requires("zlib~debug", {debug = true})
-- - add_requires("zlib~shared", {configs = {shared = true}, alias = "zlib_shared"})
--
-- - add_requires("zlib~label1")
-- - add_requires("zlib", {label = "label2"})
--
-- private package, only for installation, do not export any links/includes and environments to target
-- - add_requires("zlib", {private = true})
--
-- {system = nil/true/false}:
--   nil: get remote or system packages
--   true: only get system package
--   false: only get remote packages
--
-- {build = true}: always build packages, we do not use the precompiled artifacts
--
-- simply configs as string:
--   add_requires("boost[iostreams,system,thread,key=value] >=1.78.0")
--   add_requires("boost[iostreams,thread=n] >=1.78.0")
--   add_requires("libplist[shared,debug,codecs=[foo,bar,zoo]]")
--
function parse_requirestr(require_str)

    -- split package and version info
    local splitinfo = require_str:split('%s+')
    assert(splitinfo and #splitinfo > 0, "require(\"%s\"): invalid!", require_str)

    -- get package info
    local packageinfo = splitinfo[1]

    -- get version
    --
    -- e.g.
    --
    -- latest
    -- >=1.5.1 <1.6.0
    -- master || >1.4
    -- ~1.2.3
    -- ^1.1
    --
    local version = "latest"
    if #splitinfo > 1 then
        version = table.concat(table.slice(splitinfo, 2), " ")
    end
    assert(version, "require(\"%s\"): unknown version!", require_str)

    -- require third-party packages? e.g. brew::pcre2/libpcre2-8
    local reponame    = nil
    local packagename = nil
    if require_str:find("::", 1, true) then
        packagename = packageinfo
    else

        -- get repository name, package name and package url
        local pos = packageinfo:lastof('@', true)
        if pos then
            packagename = packageinfo:sub(pos + 1)
            reponame = packageinfo:sub(1, pos - 1)
        else
            packagename = packageinfo
        end
    end

    -- check package name
    assert(packagename, "require(\"%s\"): the package name not found!", require_str)
    return packagename, version, reponame
end

