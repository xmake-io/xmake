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

-- define rule: sign.test
rule("wdk.sign.test")

    -- add rule: wdk environment
    add_deps("wdk.env")

    -- after build
    after_build(function (target, opt)

        -- imports
        import("core.base.option")
        import("core.project.config")
        import("lib.detect.find_file")

        -- trace progress info
        cprintf("${green}[%02d%%]:${clear} ", opt.progress)
        if option.get("verbose") then
            cprint("${dim magenta}signing.test %s", path.filename(target:targetfile()))
        else
            cprint("${magenta}signing.test %s", path.filename(target:targetfile()))
        end

        -- get wdk
        local wdk = target:data("wdk")

        -- get arch
        local arch = assert(config.arch(), "arch not found!")

        -- get signtool
        local signtool = path.join(wdk.bindir, arch, "signtool.exe")
        if not os.isexec(signtool) then
            signtool = path.join(wdk.bindir, wdk.sdkver, arch, "signtool.exe")
        end
        assert(os.isexec(signtool), "signtool not found!")

        -- get inf2cat
        local inf2cat = path.join(wdk.bindir, arch, "inf2cat.exe")
        if not os.isexec(inf2cat) then
            inf2cat = path.join(wdk.bindir, wdk.sdkver, arch, "inf2cat.exe")
        end
        if not os.isexec(inf2cat) then
            inf2cat = path.join(wdk.bindir, wdk.sdkver, "x86", "inf2cat.exe")
        end
        assert(os.isexec(inf2cat), "inf2cat not found!")

        -- try to get certificate info
        local certinfo = try 
        {
            function ()
                return os.iorun("certutil -store -user my")
            end
        }
        assert(certinfo, "cannot get certificate info in local machine!")

        -- trace certificate info
        if option.get("verbose") then
            print(certinfo)
        end

        -- get thumbprint from certificate info
        local thumbprint = (certinfo:match("sha1.-: (%w+)") or ""):trim()
        assert(#thumbprint > 0, "cannot get thumbprint of certificate!")

        -- sign the target file
        os.vrunv(signtool, {"sign", "/ph", "/sha1", thumbprint, target:targetfile()})

        -- get inf file
        local infile = target:data("wdk.sign.inf")
        if not infile or not os.isfile(infile) then
            vprint("Inf2Cat task was skipped as there were no inf files to process")
            return 
        end

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
        os.vrunv(signtool, {"sign", "/ph", "/sha1", thumbprint, catfile})
    end)


