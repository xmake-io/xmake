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
import("core.platform.environment")
import("net.http")
import("net.fasturl")
import("utils.archive")

-- enter linux environment
function _enter_linux()

    -- add $programdir to $path for running xmake
    os.addenv("PATH", os.programdir())
end

-- enter macosx environment
function _enter_macosx()

    -- add $programdir to $path for running xmake
    os.addenv("PATH", os.programdir())
end

-- enter windows environment (xmake/winenv/cmd)
--
-- @note curl and tar has been placed in the xmake installation package 
--
function _enter_windows()

    -- init winenv directory
    local winenv_dir = path.translate("~/.xmake/winenv")

    -- add $programdir/winenv/cmd to $path
    os.addenv("PATH", path.join(os.programdir(), "winenv", "bin"))

    -- load winenv 
    for _, script_dir in ipairs(os.files(path.join(winenv_dir, "**", "winenv.lua")), path.directory) do
        import("winenv", {rootdir = script_dir}).main(script_dir)
        return
    end

    -- trace
    cprintf("installing winenv .. ")
    if option.get("verbose") then
        print("")
    end

    -- init winenv.zip file path
    local winenv_zip        = os.tmpfile() .. ".zip"
    local winenv_zip_tmp    = winenv_zip .. ".tmp"

    -- init winenv.zip urls
    local winenv_arch = ifelse(os.arch() == "x64", "win64", "win32")
    local winenv_urls = 
    {
        format("https://github.com/tboox/xmake-%senv/archive/master.zip", winenv_arch)
    ,   format("https://coding.net/u/waruqi/p/xmake-%senv/git/archive/master", winenv_arch)
    }
    fasturl.add(winenv_urls)

    -- download winenv.zip file
    for _, winenv_url in ipairs(fasturl.sort(winenv_urls)) do
        local ok = try
        {
            function ()

                -- no cached winenv.zip file?
                if not os.isfile(winenv_zip) or option.get("force") then

                    -- remove winenv.zip.tmp file first
                    os.rm(winenv_zip_tmp)

                    -- create a download task
                    local task = function ()
                        http.download(winenv_url, winenv_zip_tmp)
                    end

                    -- download winenv.zip
                    if option.get("verbose") then
                        task()
                    else
                        process.asyncrun(task)
                    end

                    -- attempt to remove previous winenv.zip first
                    os.rm(winenv_zip)

                    -- rename winenv.zip.tmp to winenv.zip
                    os.mv(winenv_zip_tmp, winenv_zip)
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

            -- remove winenv directory first
            os.rm(winenv_dir)

            -- extract winenv.zip file
            archive.extract(winenv_zip, winenv_dir)

            -- load winenv 
            for _, script_dir in ipairs(os.files(path.join(winenv_dir, "**", "winenv.lua")), path.directory) do
                import("winenv", {rootdir = script_dir}).main(script_dir)
                break
            end

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

-- enter host environment
function _enter_host()

    -- save old $path environment
    _g._PATH_ENV = os.getenv("PATH")

    -- init loaders
    local loaders = 
    {
        linux   = _enter_linux
    ,   macosx  = _enter_macosx
    ,   windows = _enter_windows
    }

    -- enter host environment
    local loader = loaders[os.host()]
    if loader then
        loader()
    end
end

-- leave host environment
function _leave_host()

    -- restore old $path environment
    os.setenv("PATH", _g._PATH_ENV)
end

-- enter environment
--
-- ensure that we can find some basic tools: git, make/nmake/cmake, msbuild ...
--
-- If these tools not exist, we will install it first.
--
function enter()

    -- enter host environment
    _enter_host()

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


    -- leave host environment
    _leave_host()
end
