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

-- define rule: environment
rule("wdk.env")

    -- on load
    on_load(function (target)
        import("detect.sdks.find_wdk")
        if not target:data("wdk") then
            target:data_set("wdk", assert(find_wdk(nil, {verbose = true}), "WDK not found!"))
        end
    end)

    -- clean files
    after_clean(function (target)
        for _, file in ipairs(target:data("wdk.cleanfiles")) do
            os.rm(file)
        end
        target:data_set("wdk.cleanfiles", nil)
    end)

-- define rule: *.inf
rule("wdk.inf")

    -- add rule: wdk environment
    add_deps("wdk.env")

    -- set extensions
    set_extensions(".inf", ".inx")

    -- on load
    on_load(function (target)

        -- imports
        import("core.project.config")

        -- get arch
        local arch = assert(config.arch(), "arch not found!")
        
        -- get stampinf
        local stampinf = path.join(target:data("wdk").bindir, arch, is_host("windows") and "stampinf.exe" or "stampinf")
        assert(stampinf and os.isexec(stampinf), "stampinf not found!")
        
        -- save uic
        target:data_set("wdk.stampinf", stampinf)
    end)

    -- on build file
    on_build_file(function (target, sourcefile, opt)

        -- imports
        import("core.base.option")
        import("core.project.depend")

        -- the target file
        local targetfile = path.join(target:targetdir(), path.basename(sourcefile) .. ".inf")

        -- add clean files
        target:data_add("wdk.cleanfiles", targetfile)

        -- need build this object?
        local dependfile = target:dependfile(targetfile)
        local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})
        if not depend.is_changed(dependinfo, {lastmtime = os.mtime(targetfile)}) then
            return 
        end

        -- trace progress info
        if option.get("verbose") then
            cprint("${green}[%02d%%]:${dim} compiling.wdk.inf %s", opt.progress, sourcefile)
        else
            cprint("${green}[%02d%%]:${clear} compiling.wdk.inf %s", opt.progress, sourcefile)
        end

        -- get stampinf
        local stampinf = target:data("wdk.stampinf")

        -- update the timestamp
        os.cp(sourcefile, targetfile)
        os.vrunv(stampinf, {"-d", "*", "-a", is_arch("x64") and "arm64" or "x86", "-v", "*", "-f", targetfile}, {wildcards = false})

        -- update files and values to the dependent file
        dependinfo.files = {sourcefile}
        depend.save(dependinfo, dependfile)
    end)

-- define rule: tracewpp
rule("wdk.tracewpp")

    -- add rule: wdk environment
    add_deps("wdk.env")

    -- on load
    on_load(function (target)

        -- imports
        import("core.project.config")

        -- get wdk
        local wdk = target:data("wdk")

        -- get arch
        local arch = assert(config.arch(), "arch not found!")
        
        -- get tracewpp
        local tracewpp = path.join(wdk.bindir, arch, is_host("windows") and "tracewpp.exe" or "tracewpp")
        assert(tracewpp and os.isexec(tracewpp), "tracewpp not found!")
        
        -- save tracewpp
        target:data_set("wdk.tracewpp", tracewpp)

        -- save output directory
        target:data_set("wdk.tracewpp.outputdir", path.join(config.buildir(), ".wpp", config.get("mode") or "generic", config.get("arch") or os.arch(), target:name()))
        
        -- save config directory
        target:data_set("wdk.tracewpp.configdir", path.join(wdk.bindir, wdk.sdkver, "WppConfig", "Rev1"))
    end)

    -- before build file
    before_build_file(function (target, sourcefile, opt)

        -- imports
        import("core.base.option")

        -- get tracewpp
        local tracewpp = target:data("wdk.tracewpp")

        -- get outputdir
        local outputdir = target:data("wdk.tracewpp.outputdir")

        -- trace progress info
        if option.get("verbose") then
            cprint("${green}[%02d%%]:${dim} compiling.wdk.tracewpp %s", opt.progress, sourcefile)
        else
            cprint("${green}[%02d%%]:${clear} compiling.wdk.tracewpp %s", opt.progress, sourcefile)
        end

        -- get configdir
        local configdir = target:data("wdk.tracewpp.configdir")

        -- init args
        local args = {}
        if target:rule("wdk.kmdf.driver") then
            table.insert(args, "-km")
            table.insert(args, "-gen:{km-WdfDefault.tpl}*.tmh")
        end
        local flags = target:values("wdk.tracewpp.flags")
        if flags then
            table.join2(args, flags)
        end
        table.insert(args, "-cfgdir:" .. configdir)
        table.insert(args, "-odir:" .. outputdir)
        table.insert(args, sourcefile)

        -- update the timestamp
        if not os.isdir(outputdir) then
            os.mkdir(outputdir)
        end
        os.vrunv(tracewpp, args, {wildcards = false})

        -- add includedirs
        target:add("includedirs", outputdir)

        -- add clean files
        target:data_add("wdk.cleanfiles", outputdir)
    end)

-- define rule: umdf driver
rule("wdk.umdf.driver")

    -- add rules
    add_deps("wdk.inf")

    -- on load
    on_load(function (target)
        import("load").umdf_driver(target)
    end)

-- define rule: umdf binary
rule("wdk.umdf.binary")

    -- add rules
    add_deps("wdk.inf")

    -- on load
    on_load(function (target)
        import("load").umdf_binary(target)
    end)

-- define rule: kmdf driver
rule("wdk.kmdf.driver")

    -- add rules
    add_deps("wdk.inf")

    -- on load
    on_load(function (target)
        import("load").kmdf_driver(target)
    end)

-- define rule: kmdf binary
rule("wdk.kmdf.binary")

    -- add rules
    add_deps("wdk.inf")

    -- on load
    on_load(function (target)
        import("load").kmdf_binary(target)
    end)

    -- after build
    after_build(function (target)

        -- imports
        import("core.project.config")

        -- get wdk
        local wdk = target:data("wdk")

        -- copy wdf redist dll libraries (WdfCoInstaller01011.dll, ..) to the target directory
        os.cp(path.join(wdk.sdkdir, "Redist", "wdf", config.arch(), "*.dll"), target:targetdir())

        -- add clean files
        target:data_add("wdk.cleanfiles", os.files(path.join(target:targetdir(), "*.dll")))
    end)

