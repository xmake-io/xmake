--!A cross-platform build utility based on Lua
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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        main.lua
--

-- imports
import("core.base.semver")
import("core.base.option")
import("core.base.task")
import("devel.git")
import("net.fasturl")
import("actions.require.impl.environment", {rootdir = os.programdir()})

-- do uninstall
function _uninstall()
end

-- do install
function _install(sourcedir)

    -- trace
    cprintf("${yellow}  => ${clear}installing ..")
    io.flush()

    -- install it 
    os.cd(sourcedir)
    if is_host("windows") then
        os.vrun("xmake -P core")
        os.cp("xmake", os.programdir())
        os.cp("core/build/xmake.exe", os.programfile())
    else
        if os.programdir():startswith("/usr/") then
            os.vrun("make build")
            os.vrun("make install") -- TODO sudo
        else
            os.vrun("./scripts/get.sh __local__")
        end
    end
    
    -- trace
    cprint("\r${yellow}  => ${clear}install to %s .. ${green}ok", os.programdir())
end

-- main
function main()

    -- only uninstall it
    if option.get("uninstall") then
        return _uninstall()
    end

    -- enter environment 
    environment.enter()

    -- sort main urls
    local mainurls = {"https://github.com/tboox/xmake.git", "https://gitlab.com/tboox/xmake.git", "https://gitee.com/tboox/xmake.git"}
    fasturl.add(mainurls)
    mainurls = fasturl.sort(mainurls)

    -- get version
    local version = nil
    for _, url in ipairs(mainurls) do
        local tags, branches = git.refs(url)
        if tags or branches then
            version = semver.select(option.get("xmakever") or "lastest", tags or {}, tags or {}, branches or {})
            break
        end
    end
    if not version then
        version = "master"
    end

    -- trace
    print("update version: %s ..", version)

    -- download the source code
    local sourcedir = path.join(os.tmpdir(), "xmakesrc", version)
    for idx, url in ipairs(mainurls) do
        cprintf("${yellow}  => ${clear}clone %s ..", url)
        io.flush()
        local ok = try
        {
            function ()
                os.tryrm(sourcedir)
                if version:find('.', 1, true) then
                    git.clone(url, {outputdir = sourcedir})
                    git.checkout(version, {repodir = sourcedir})
                else
                    git.clone(url, {depth = 1, branch = version, outputdir = sourcedir})
                end
                return true
            end,
            catch 
            {
                function (errors)
                    vprint(errors)
                end
            }
        }
        if ok then
            cprint("\r${yellow}  => ${clear}clone %s .. ${green}ok", url)
            break
        else
            cprint("\r${yellow}  => ${clear}clone %s .. ${red}failed", url)
        end
        if not ok and idx == #mainurls then
            raise("download failed!")
        end
    end

    -- leave environment 
    environment.leave()

    -- do install
    _install(sourcedir)
end

