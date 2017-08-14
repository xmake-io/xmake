--!The Make-like install Utility based on Lua
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
-- @file        install.lua
--

-- imports
import("core.base.option")
import("core.project.target")
import("build")

-- install for xmake file
function _install_for_xmakefile(package)

    -- package to install directory
    os.vrun("xmake p -o %s", package:installdir())

    -- ok
    return true
end

-- install for generic
function _install_for_generic(package)

    -- the package name
    local name = package:name()

    -- the install directory
    local installdir = path.join(package:installdir(), name .. ".pkg")

    -- the linkdir
    local linkdir = path.join(installdir, "lib/$(mode)/$(plat)/$(arch)")
    os.mkdir(linkdir)

    -- the includedir 
    local includedir = path.join(installdir, "inc")
    os.mkdir(includedir)

    -- the prefix directory exists?
    local prefixdir = ""
    if os.isdir(".prefix") and not os.emptydir(".prefix") then
        prefixdir = ".prefix" .. path.seperator()
    end

    -- install the library files and ignore hidden files (.xxx)
    if not os.trycp(prefixdir .. "**" .. target.filename("*", "static"), linkdir) and 
       not os.trycp(prefixdir .. "**" .. target.filename("*", "shared"), linkdir) then
        raise("the library files not found in package %s", name)
    end

    -- install the header files
    for _, headerfile in ipairs(table.join((os.files(prefixdir .. "**.h")), (os.files(prefixdir .. "**.hpp")))) do

        -- the destinate header
        local dstheaderfile = nil
        if #prefixdir > 0 then
            dstheaderfile = path.absolute(path.relative(headerfile, path.join(prefixdir, "include")), includedir)
        else
            dstheaderfile = path.join(includedir, path.filename(headerfile))
        end

        -- install header file
        os.cp(headerfile, dstheaderfile)
    end

    -- make xmake.lua 
    local file = io.open(path.join(installdir, "xmake.lua"), "w")
    if file then

        -- the xmake.lua content
        local content = [[ 
-- the %s package
option("%s")

    -- show menu
    set_showmenu(true)

    -- set category
    set_category("package")

    -- set description
    set_description("The %s package")

    -- add defines to config.h if checking ok
    add_defines_h_if_ok("$(prefix)_PACKAGE_HAVE_%s")

    -- add links for checking
    add_links("%s")

    -- add link directories
    add_linkdirs("lib/$(mode)/$(plat)/$(arch)")

    -- add include directories
    add_includedirs("inc")
]]

        -- save file
        file:writef(content, name, name, name, name:upper(), name)

        -- exit file
        file:close()
    end

    -- ok
    return true
end

-- on install the given package
function _on_install_package(package)

    -- init install scripts
    local installscripts =
    {
        {"xmake.lua",       _install_for_xmakefile    }
    ,   {"*",               _install_for_generic      }
    }

    -- attempt to install it
    for _, installscript in pairs(installscripts) do

        -- save the current directory 
        local oldir = os.curdir()

        -- try installing 
        local ok = try
        {
            function ()

                -- attempt to install it if file exists
                local files = os.files(installscript[1])
                if #files > 0 then
                    return installscript[2](package)
                end
            end,

            catch
            {
                function (errors)

                    -- trace verbose info
                    if errors then
                        vprint(errors)
                    end
                end
            }
        }

        -- restore directory
        os.cd(oldir)

        -- ok?
        if ok then return end
    end

    -- failed
    raise("attempt to install package %s failed!", package:name())
end

-- install the given package
function main(package)

    -- skip phony package without urls
    if #package:urls() == 0 then
        return
    end

    -- get working directory of this package
    local workdir = package:cachedir()

    -- enter source files directory
    local oldir = nil
    for _, srcdir in ipairs(os.dirs(path.join(workdir, "source", "*"))) do
        oldir = os.cd(srcdir)
        break
    end

    -- trace
    cprintf("${yellow}  => ${clear}installing %s-%s .. ", package:name(), package:version_str())
    if option.get("verbose") then
        print("")
    end

    -- install it
    try
    {
        function ()

            -- the package scripts
            local scripts =
            {
                package:script("install_before") 
            ,   package:script("install", _on_install_package)
            ,   package:script("install_after") 
            }

            -- create the install task
            local installtask = function () 

                -- build it
                build(package)

                -- install it
                for i = 1, 3 do
                    local script = scripts[i]
                    if script ~= nil then
                        script(package)
                    end
                end
            end

            -- install package
            if option.get("verbose") then
                installtask()
            else
                process.asyncrun(installtask)
            end

            -- trace
            cprint("${green}ok")
        end,

        catch
        {
            function (errors)

                -- verbose?
                if option.get("verbose") and errors then
                    cprint("${bright red}error: ${clear}%s", errors)
                end

                -- trace
                cprint("${red}failed")

                -- failed
                raise("install failed!")
            end
        }
    }

    -- leave source codes directory
    os.cd(oldir)
end
