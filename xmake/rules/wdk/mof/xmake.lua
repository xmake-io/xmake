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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define rule: *.mof
rule("wdk.mof")

    -- add rule: wdk environment
    add_deps("wdk.env")

    -- set extensions
    set_extensions(".mof")

    -- before load
    before_load(function (target)

        -- imports
        import("core.project.config")
        import("lib.detect.find_program")

        -- get arch
        local arch = assert(config.arch(), "arch not found!")

        -- get wdk
        local wdk = target:data("wdk")

        -- get mofcomp
        local mofcomp = find_program("mofcomp", {check = function (program)
            local tmpmof = os.tmpfile()
            io.writefile(tmpmof, "")
            os.run("%s %s", program, tmpmof)
            os.tryrm(tmpmof)
        end})
        assert(mofcomp, "mofcomp not found!")

        -- get wmimofck
        local wmimofck = nil
        if arch == "x64" then
            wmimofck = path.join(wdk.bindir, wdk.sdkver, "x64", "wmimofck.exe")
            if not os.isexec(wmimofck) then
                wmimofck = path.join(wdk.bindir, wdk.sdkver, "x86", "x64", "wmimofck.exe")
            end
        else
            wmimofck = path.join(wdk.bindir, wdk.sdkver, "x86", "wmimofck.exe")
        end
        assert(wmimofck and os.isexec(wmimofck), "wmimofck not found!")

        -- save mofcomp and wmimofck
        target:data_set("wdk.mofcomp", mofcomp)
        target:data_set("wdk.wmimofck", wmimofck)
    end)

    -- before build file
    before_build_file(function (target, sourcefile, opt)

        -- imports
        import("core.base.option")
        import("core.theme.theme")
        import("core.project.depend")
        import("private.utils.progress")

        -- get mofcomp
        local mofcomp = target:data("wdk.mofcomp")

        -- get wmimofck
        local wmimofck = target:data("wdk.wmimofck")

        -- get output directory
        local outputdir = path.join(target:autogendir(), "rules", "wdk", "mof")

        -- add includedirs
        target:add("includedirs", outputdir)

        -- get header file
        local header = target:values("wdk.mof.header", sourcefile)
        local headerfile = path.join(outputdir, header and header or (path.basename(sourcefile) .. ".h"))

        -- get some temporary file
        local sourcefile_mof     = path.join(outputdir, path.filename(sourcefile))
        local targetfile_mfl     = path.join(outputdir, "." .. path.basename(sourcefile) .. ".mfl")
        local targetfile_mof     = path.join(outputdir, "." .. path.basename(sourcefile) .. ".mof")
        local targetfile_mfl_mof = path.join(outputdir, "." .. path.basename(sourcefile) .. ".mfl.mof")
        local targetfile_bmf     = path.join(outputdir, path.basename(sourcefile) .. ".bmf")
        local outputdir_htm      = path.join(outputdir, "htm")
        local targetfile_vbs     = path.join(outputdir, path.basename(sourcefile) .. ".vbs")

        -- need build this object?
        local dependfile = target:dependfile(headerfile)
        local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})
        if not depend.is_changed(dependinfo, {lastmtime = os.mtime(headerfile), values = args}) then
            return
        end

        -- trace progress info
        progress.show(opt.progress, "${color.build.object}compiling.wdk.mof %s", sourcefile)

        -- ensure the output directory
        if not os.isdir(outputdir) then
            os.mkdir(outputdir)
        end

        -- copy *.mof to output directory
        os.cp(sourcefile, sourcefile_mof)

        -- do mofcomp
        os.vrunv(mofcomp, {"-Amendment:ms_409", "-MFL:" .. targetfile_mfl, "-MOF:" .. targetfile_mof, sourcefile_mof})

        -- do wmimofck
        os.vrunv(wmimofck, {"-y" .. targetfile_mof, "-z" .. targetfile_mfl, targetfile_mfl_mof})

        -- do mofcomp to generate *.bmf
        os.vrunv(mofcomp, {"-B:" .. targetfile_bmf, targetfile_mfl_mof})

        -- do wmimofck to generate *.h
        os.vrunv(wmimofck, {"-h" .. headerfile, "-w" .. outputdir_htm, "-m", "-t" .. targetfile_vbs, targetfile_bmf})

        -- update files and values to the dependent file
        dependinfo.files  = {sourcefile}
        dependinfo.values = args
        depend.save(dependinfo, dependfile)
    end)

