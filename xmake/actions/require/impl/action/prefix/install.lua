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
import("uninstall")

-- install package to the prefix directory
function main(package)

    -- uninstall the prefix package files first
    uninstall(package)

    -- get prefix and install directory
    local prefixdir  = package:prefixdir()
    local installdir = package:installdir()

    -- scan all installed files
    local installfiles = {}
    if is_host("windows") then
        if package:kind() == "binary" then
            table.join2(installfiles, (os.files(path.join(installdir, "**"))))
        else
            table.join2(installfiles, (os.files(path.join(package:installdir("lib"), "**"))))
            table.join2(installfiles, (os.files(path.join(package:installdir("include"), "**"))))
        end
    else
        if package:kind() == "binary" then
            table.join2(installfiles, (os.files(path.join(package:installdir("bin"), "*"))))
        else
            table.join2(installfiles, (os.files(path.join(package:installdir("lib"), "**.a"))))
            table.join2(installfiles, (os.files(path.join(package:installdir("lib"), is_plat("macosx") and "**.dylib" or "**.so"))))
            table.join2(installfiles, (os.files(path.join(package:installdir("lib", "pkgconfig"), "**.pc"))))
            table.join2(installfiles, (os.filedirs(path.join(package:installdir("include"), "*"))))
        end
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

                -- install file
                if is_host("windows") then
                    -- copy the whole file to the prefix directory
                    os.cp(installfile, path.absolute(relativefile, prefixdir))
                else
                    -- only link file to the prefix directory
                    os.ln(installfile, path.absolute(relativefile, prefixdir))
                end

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

