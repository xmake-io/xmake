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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        install.lua
--

-- imports
import("core.base.option")
import("core.project.target")
import("test")
import("filter")

-- uninstall package from the prefix directory
function uninstall_prefix(package)

    -- remove the previous installed files
    local prefixdir = package:prefixdir()
    for _, relativefile in ipairs(package:prefixinfo().installed) do

        -- trace
        vprint("removing %s ..", relativefile)

        -- remove file
        local prefixfile = path.absolute(relativefile, prefixdir)
        os.tryrm(prefixfile)
 
        -- remove it if the parent directory is empty
        local parentdir = path.directory(prefixfile)
        while parentdir and os.isdir(parentdir) and os.emptydir(parentdir) do
            os.tryrm(parentdir)
            parentdir = path.directory(parentdir)
        end
    end

    -- unregister this package
    package:unregister()

    -- remove the prefix file
    os.tryrm(package:prefixfile())
end

-- install package to the prefix directory
function install_prefix(package)

    -- uninstall the prefix package files first
    uninstall_prefix(package)

    -- get prefix and install directory
    local prefixdir  = package:prefixdir()
    local installdir = package:installdir()

    -- scan all installed files
    local installfiles = {}
    if package:kind() == "binary" then
        table.join2(installfiles, (os.files(path.join(installdir, "**"))))
    else
        table.join2(installfiles, (os.files(path.join(package:installdir("lib"), "**"))))
        table.join2(installfiles, (os.files(path.join(package:installdir("include"), "**"))))
    end

    -- trace
    vprint("installing %s to %s ..", installdir, prefixdir)

    -- install to the prefix directory
    local relativefiles = {}
    try
    {
        function ()
            for _, installfile in ipairs(installfiles) do

                -- get relative file
                local relativefile = path.relative(installfile, installdir)

                -- trace
                vprint("installing %s ..", relativefile)

                -- copy file
                os.cp(installfile, path.absolute(relativefile, prefixdir))

                -- save this relative file
                table.insert(relativefiles, relativefile)
            end
        end,
        catch 
        {
            function (errors)
                raise(errors)
            end
        },
        finally
        {
            function ()
                -- save the prefix info to file
                local prefixinfo = package:prefixinfo()
                prefixinfo.installed = relativefiles
                io.save(package:prefixfile(), prefixinfo)

                -- register this package
                package:register()
            end
        }
    }
end

-- install the given package
function main(package)

    -- get working directory of this package
    local workdir = package:cachedir()

    -- enter the working directory
    local oldir = nil
    if #package:urls() > 0 then
        -- only one root directory? skip it
        local filedirs = os.filedirs(path.join(workdir, "source", "*"))
        if #filedirs == 1 and os.isdir(filedirs[1]) then
            oldir = os.cd(filedirs[1])
        else
            oldir = os.cd(path.join(workdir, "source"))
        end
    end
    if not oldir then
        os.mkdir(workdir)
        oldir = os.cd(workdir) 
    end

    -- init tipname 
    local tipname = package:name()
    if package:version_str() then
        tipname = tipname .. "-" .. package:version_str()
    end

    -- trace
    cprintf("${yellow}  => ${clear}installing %s .. ", tipname)
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
            ,   package:script("install")
            ,   package:script("install_after") 
            }

            -- create the install task
            local installtask = function () 

                -- clean the install directory first
                os.tryrm(package:installdir())

                -- install it
                for i = 1, 3 do
                    local script = scripts[i]
                    if script ~= nil then
                        filter.call(script, package)
                    end
                end

                -- install to the prefix directory
                install_prefix(package)

                -- test it
                test(package)
            end

            -- install package
            if option.get("verbose") then
                installtask()
            else
                process.asyncrun(installtask)
            end

            -- fetch package and force to flush the cache
            assert(package:fetch({force = true}), "fetch %s failed!", tipname)

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
                if not package:requireinfo().optional then
                    raise("install failed!")
                end
            end
        }
    }

    -- leave source codes directory
    os.cd(oldir)
end
