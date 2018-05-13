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
-- @file        xmake.lua
--

-- define rule: *.mof
rule("wdk.mof")

    -- add rule: wdk environment
    add_deps("wdk.env")

    -- set extensions
    set_extensions(".mof")

    -- on load
    on_load(function (target)

        -- imports
        import("core.project.config")
        import("lib.detect.find_program")

        -- get arch
        local arch = assert(config.arch(), "arch not found!")

        -- get mofcomp
        local mofcomp = find_program("mofcomp", {check = function (program) 
            local tmpmof = os.tmpfile() 
            io.writefile(tmpmof, "")
            os.run("%s %s", program, tmpmof)
            os.tryrm(tmpmof)
        end})
        assert(mofcomp, "mofcomp not found!")
        
        -- get wmimofck
        local wmimofck = path.join(target:data("wdk").bindir, "x86", arch, is_host("windows") and "wmimofck.exe" or "wmimofck")
        assert(wmimofck and os.isexec(wmimofck), "wmimofck not found!")
        
        -- save mofcomp and wmimofck
        target:data_set("wdk.mofcomp", mofcomp)
        target:data_set("wdk.wmimofck", wmimofck)

        -- save output directory
        target:data_set("wdk.mof.outputdir", path.join(config.buildir(), ".wdk", "mof", config.get("mode") or "generic", config.get("arch") or os.arch(), target:name()))
    end)

    -- before build file
    before_build_file(function (target, sourcefile, opt)

        -- imports
        import("core.base.option")
        import("core.project.depend")

        -- get mofcomp
        local mofcomp = target:data("wdk.mofcomp")

        -- get wmimofck
        local wmimofck = target:data("wdk.wmimofck")

        -- get output directory
        local outputdir = target:data("wdk.mof.outputdir")

        -- init args
        local args = {}
        local flags = target:values("wdk.mof.flags")
        if flags then
            table.join2(args, flags)
        end

        -- add includedirs
        target:add("includedirs", outputdir)

        -- need build this object?
        --[[
        local dependfile = target:dependfile(headerfile)
        local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})
        if not depend.is_changed(dependinfo, {lastmtime = os.mtime(headerfile), values = args}) then
            return 
        end
        ]]

        -- trace progress info
        if option.get("verbose") then
            cprint("${green}[%02d%%]:${dim} compiling.wdk.mof %s", opt.progress, sourcefile)
        else
            cprint("${green}[%02d%%]:${clear} compiling.wdk.mof %s", opt.progress, sourcefile)
        end

        -- do wmimofck 
        --[[
        if not os.isdir(outputdir) then
            os.mkdir(outputdir)
        end
        os.vrunv(wmimofck, args)
        ]]

        -- update files and values to the dependent file
        --[[
        dependinfo.files  = {sourcefile}
        dependinfo.values = args
        depend.save(dependinfo, dependfile)
        ]]
    end)

