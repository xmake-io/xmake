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

-- define rule: package *.cab
rule("wdk.package.cab")

    -- on package
    on_package(function (target)

        -- imports
        import("core.base.option")
        import("core.project.config")
        import("lib.detect.find_program")

        -- the output directory
        local outputdir = path.join(option.get("outputdir") or config.buildir(), "drivers", target:name())
        local mode = config.mode()
        if mode then
            outputdir = path.join(outputdir, mode)
        end
        local arch = config.arch()
        if arch then
            outputdir = path.join(outputdir, arch)
        end

        -- the package file
        local packagefile = path.join(outputdir, target:name() .. ".cab")

        -- the .ddf file
        local ddfile = os.tmpfile(target:targetfile()) .. ".ddf"

        -- trace progress info
        if option.get("verbose") then
            cprint("${dim magenta}packaging %s", packagefile)
        else
            cprint("${magenta}packaging %s", packagefile)
        end

        -- get makecab
        local makecab = find_program("makecab", {check = "/?"})
        assert(makecab, "makecab not found!")

        -- make .ddf file
        local file = io.open(ddfile, "w")
        if file then
            file:print("; %s.ddf", target:name())
            file:print(";")
            file:print(".OPTION EXPLICIT     ; Generate errors")
            file:print(".Set CabinetFileCountThreshold=0")
            file:print(".Set FolderFileCountThreshold=0")
            file:print(".Set FolderSizeThreshold=0")
            file:print(".Set MaxCabinetSize=0")
            file:print(".Set MaxDiskFileCount=0")
            file:print(".Set MaxDiskSize=0")
            file:print(".Set CompressionType=MSZIP")
            file:print(".Set Cabinet=on")
            file:print(".Set Compress=on")
            file:print(";Specify file name for new cab file")
            file:print(".Set CabinetNameTemplate=%s.cab", target:name())
            file:print("; Specify the subdirectory for the files.  ")
            file:print("; Your cab file should not have files at the root level,")
            file:print("; and each driver package must be in a separate subfolder.")
            file:print(".Set DiskDirectoryTemplate=%s", outputdir)
            file:print(";Specify files to be included in cab file")
            local infile = target:data("wdk.sign.inf")
            if infile and os.isfile(infile) then
                file:print(path.absolute(infile))
            end
            file:print(path.absolute(target:targetfile()))
            file:close()
        end

        -- make .cab
        os.vrunv(makecab, {"/f", ddfile})

        -- save this package file for signing (wdk.sign.* rules)
        target:data_set("wdk.sign.cab", packagefile)
    end)


