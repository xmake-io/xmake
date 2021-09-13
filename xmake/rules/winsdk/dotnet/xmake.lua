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
-- @file        xmake.lua
--

-- define rule: dotnet
rule("win.sdk.dotnet")

    -- before load
    on_load(function (target)

        -- imports
        import("core.project.config")
        import("detect.sdks.find_dotnet")

        -- load dotnet environment
        if not target:data("win.sdk.dotnet") then

            -- find dotnet
            local dotnet = assert(find_dotnet(nil, {verbose = true}), "dotnet not found!")

            -- add link directory
            target:add("linkdirs", path.join(dotnet.libdir, "um", config.arch()))

            -- save dotnet
            target:data_set("win.sdk.dotnet", dotnet)
        end
    end)

    -- before build file
    before_build_file(function (target, sourcefile, opt)

        -- get dotnet
        local dotnet = target:data("win.sdk.dotnet")
        if not dotnet then

            -- imports
            import("core.project.config")
            import("detect.sdks.find_dotnet")

            -- find dotnet
            dotnet = assert(find_dotnet(nil, {verbose = true}), "dotnet not found!")

            -- add link directory
            target:add("linkdirs", path.join(dotnet.libdir, "um", config.arch()))

            -- save dotnet
            target:data_set("win.sdk.dotnet", dotnet)
        end

        -- get file config
        local fileconfig = target:fileconfig(sourcefile) or {}

        -- add cxflags to the given source file
        --
        -- add_files(sourcefile, {force = {cxflags = "/clr"}})
        --
        fileconfig.force = fileconfig.force or {}
        fileconfig.force.cxflags = fileconfig.force.cxflags or {}
        table.insert(fileconfig.force.cxflags, "/clr")

        -- add include directory to given source file
        fileconfig.includedirs = fileconfig.includedirs or {}
        table.insert(fileconfig.includedirs, path.join(dotnet.includedir, "um"))

        -- update file config
        target:fileconfig_set(sourcefile, fileconfig)
    end)
