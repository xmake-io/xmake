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

-- define rule: sign
--
-- values:
--   - wdk.sign.enabled:   true/false (default: true)
--   - wdk.sign.mode:      test/release (default: test)
--   - wdk.sign.company:   tboox.org (for release signing)
--   - wdk.sign.certfile:  signcert.cer (for release signing)
--   - wdk.sign.timestamp: http://timestamp.verisign.com/scripts/timstamp.dll
--
rule("wdk.sign")

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

        -- get inf2cat
        local inf2cat = path.join(wdk.bindir, arch, "inf2cat.exe")
        if not os.isexec(inf2cat) then
            inf2cat = path.join(wdk.bindir, wdk.sdkver, arch, "inf2cat.exe")
        end
        if not os.isexec(inf2cat) then
            inf2cat = path.join(wdk.bindir, wdk.sdkver, "x86", "inf2cat.exe")
        end
        assert(os.isexec(inf2cat), "inf2cat not found!")
        target:data_set("wdk.sign.inf2cat", inf2cat)
    end)

    -- after build
    after_build(function (target, opt)

        -- imports
        import("sign")
        import("core.base.option")
        import("core.project.config")
        import("core.project.depend")
        import("lib.detect.find_file")

        -- need build this object?
        local tempfile = os.tmpfile(target:targetfile())
        local dependfile = tempfile .. ".d"
        local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})
        if not depend.is_changed(dependinfo, {lastmtime = os.mtime(tempfile)}) then
            return 
        end

        -- get sign mode
        local signmode = target:values("wdk.sign.mode") or "test"

        -- add clean files
        target:data_add("wdk.cleanfiles", {tempfile, dependfile})

        -- trace progress info
        cprintf("${green}[%02d%%]:${clear} ", opt.progress)
        if option.get("verbose") then
            cprint("${dim magenta}signing.%s %s", signmode, path.filename(target:targetfile()))
        else
            cprint("${magenta}signing.%s %s", signmode, path.filename(target:targetfile()))
        end

        -- get arch
        local arch = assert(config.arch(), "arch not found!")

        -- get inf2cat
        local inf2cat = target:data("wdk.sign.inf2cat")

        -- sign the target file
        sign(target, target:targetfile(), signmode)

        -- get inf file
        local infile = target:data("wdk.sign.inf")
        if infile and os.isfile(infile) then

            -- do inf2cat
            local inf2cat_dir = path.directory(target:targetfile())
            local inf2cat_argv = {"/driver:" .. inf2cat_dir}
            local inf2cat_os = target:values("wdk.inf2cat.os") or {"XP_" .. arch, "7_" .. arch, "8_" .. arch, "10_" .. arch}
            table.insert(inf2cat_argv, "/os:" .. table.concat(table.wrap(inf2cat_os), ','))
            os.vrunv(inf2cat, inf2cat_argv)

            -- get *.cat file path from the output directory
            local catfile = find_file("*.cat", inf2cat_dir)
            assert(catfile, "*.cat not found!")

            -- sign *.cat file
            sign(target, catfile, signmode)
        else
            -- trace
            vprint("Inf2Cat task was skipped as there were no inf files to process")
        end

        -- update files and values to the dependent file
        dependinfo.files = {target:targetfile()}
        depend.save(dependinfo, dependfile)
        io.writefile(tempfile, "")
    end)

    -- after package
    after_package(function (target)

        -- imports
        import("sign")
        import("core.base.option")

        -- get signtool
        local signtool = target:data("wdk.sign.signtool")

        -- get package file
        local packagefile = target:data("wdk.sign.cab")
        assert(packagefile and os.isfile(packagefile), "the driver package file(.cab) not found!")

        -- get sign mode
        local signmode = target:values("wdk.sign.mode") or "test"

        -- trace progress info
        if option.get("verbose") then
            cprint("${dim magenta}signing.%s %s", signmode, path.filename(packagefile))
        else
            cprint("${magenta}signing.%s %s", signmode, path.filename(packagefile))
        end

        -- sign package file
        sign(target, packagefile, signmode)
    end)
