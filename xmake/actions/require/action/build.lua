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
-- @file        build.lua
--

-- imports
import("core.base.option")
import("core.tool.tool")
import("core.project.config")
import("core.sandbox.sandbox")
import(".environment")

-- build for xmake file
function _build_for_xmakefile(package)

    -- configure it first
    if config.plat() and config.arch() then
        os.vrun("$(xmake) f -p $(plat) -a $(arch) -c")
    else
        os.vrun("$(xmake) f -c")
    end

    -- build it
    os.vrun("$(xmake) -r")
end

-- build for makefile
function _build_for_makefile(package)

    -- build it
    os.vrun("$(make)")
end

-- build for configure
function _build_for_configure(package)

    -- configure it first
    os.vrun("./configure")

    -- build it
    _build_for_makefile(package)
end

-- build for cmakelist
function _build_for_cmakelists(package)

    -- make makefile first
    os.vrun("cmake .")

    -- build it
    _build_for_makefile(package)
end

-- on build the given package
function _on_build_package(package)

    -- TODO *.vcproj, premake.lua, scons, autogen.sh, Makefile.am, ...
    -- init build scripts
    local buildscripts =
    {
        {"xmake.lua",       _build_for_xmakefile    }
    ,   {"CMakeLists.txt",  _build_for_cmakelists   }
    ,   {"configure",       _build_for_configure    }
    ,   {"[mM]akefile",     _build_for_makefile     }
    }

    -- attempt to build it
    for _, buildscript in pairs(buildscripts) do
        local ok = try
        {
            function ()

                -- attempt to build it if file exists
                local files = os.files(buildscript[1])
                if #files > 0 then
                    buildscript[2](package)
                    return true
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

        -- ok?
        if ok then return end
    end

    -- failed
    raise("attempt to build package %s failed!", package:name())
end

-- run script
function _run_script(script, package)

    -- register filter handler before building
    sandbox.filter_register(script, "package.build", function (var) 
        
        -- attempt to get shellname from tool 
        local shellname = tool.shellname(var)
        if shellname then
            result = shellname
        end

        -- ok
        return shellname
    end)

    -- run it
    script(package)

    -- cancel filter handler before building
    sandbox.filter_register(script, "package.build", nil)
end

-- build the given package
function main(package)

    -- skip phony package without urls
    if #package:urls() == 0 then
        return
    end

    -- trace
    cprintf("${yellow}  => ${clear}building %s-%s .. ", package:name(), package:version())
    if option.get("verbose") then
        print("")
    end

    -- enter source codes directory
    local oldir = os.cd("source")

    -- build it
    try
    {
        function ()

            -- the package scripts
            local scripts =
            {
                package:get("build_before") 
            ,   package:get("build")  or _on_build_package
            ,   package:get("build_after") 
            }

            -- run the package scripts
            local buildtask = function () 

                -- enter environment
                environment.enter()

                -- build it
                for i = 1, 3 do
                    local script = scripts[i]
                    if script ~= nil then
                        _run_script(script, package)
                    end
                end

                -- leave environment
                environment.leave()
            end

            -- download package file
            if option.get("verbose") then
                buildtask()
            else
                process.asyncrun(buildtask)
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
                raise("build failed!")
            end
        }
    }

    -- leave source codes directory
    os.cd(oldir)
end
