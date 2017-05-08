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
-- @file        environment.lua
--

-- imports
import("core.base.option")
import("core.tool.unarchiver")
import("core.tool.downloader")
import("core.platform.environment")
import("fasturl")

-- load linux environment
function _load_linux()
end

-- load macosx environment
function _load_macosx()
end

-- load windows environment (xmake/winenv/cmd)
--
-- @note curl and tar has been placed in the xmake installation package 
--
function _load_windows()

    -- init winenv directory
    local winenv_dir = path.translate("~/.xmake/winenv")
    local winenv_cmd_dir = path.join(winenv_dir, "cmd")

    -- add $programdir/winenv/cmd and ~/.xmake/winenv/cmd to $path
    os.setenv("PATH", (os.getenv("PATH") or "") .. ";" .. path.join(os.programdir(), "winenv", "cmd") .. ";" .. winenv_cmd_dir)

    -- check git 
    if os.isfile(path.join(winenv_cmd_dir, "git.exe")) then
        return
    end

    -- trace
    cprintf("installing winenv .. ")
    if option.get("verbose") then
        print("")
    end

    -- init winenv.zip file path
    local winenv_zip = os.tmpfile() .. ".zip"

    -- init winenv.zip urls
    local winenv_arch = ifelse(os.arch() == "x64", "win64", "win32")
    local winenv_urls = 
    {
        format("https://github.com/tboox/xmake-%senv/archive/master.zip", winenv_arch)
    ,   format("https://git.oschina.net/tboox/xmake-%senv/repository/archive/master", winenv_arch)
    }
    fasturl.add(winenv_urls)

    -- download winenv.zip file
    for _, winenv_url in ipairs(fasturl.sort(winenv_urls)) do
        local ok = try
        {
            function ()

                -- attempt to remove winenv.zip file first
                os.tryrm(winenv_zip)

                -- create a download task
                local task = function ()
                    downloader.download(winenv_url, winenv_zip)
                end

                -- download winenv.zip
                if option.get("verbose") then
                    task()
                else
                    process.asyncrun(task)
                end

                -- ok
                return true
            end,

            catch
            {
                function (errors)

                    -- verbose?
                    if option.get("verbose") then
                        cprint("${bright red}error: ${clear}%s", errors)
                    end
                end
            }
        }

        -- ok?
        if ok then 

            -- attempt to remove winenv directory first
            os.tryrm(winenv_dir)

            -- extract winenv.zip file
            unarchiver.extract(winenv_zip, winenv_dir)
            
            -- trace
            cprint("${green}ok")

            -- ok
            return 
        end 
    end

    -- failed
    cprint("${red}failed")
    raise()
end

-- laod host environment
--
-- ensure that we can find some basic tools: git, make/nmake/cmake, msbuild ...
--
-- If these tools not exist, we will install it first.
--
function load()

    -- init loaders
    local loaders = 
    {
        linux   = _load_linux
    ,   macosx  = _load_macosx
    ,   windows = _load_windows
    }

    -- load host environment
    local loader = loaders[os.host()]
    if loader then
        loader()
    end
end

-- enter environment
function enter()

    -- set search pathes of toolchains 
    environment.enter("toolchains")

    -- TODO set toolchains for CC, LD, ..

    -- TODO set flags of toolchains
end

-- leave environment
function leave()

    -- restore search pathes of toolchains
    environment.leave("toolchains")

    -- TODO restore toolchains for CC, LD
    
    -- TODO set flags of toolchains
end
