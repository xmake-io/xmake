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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define rule: *.mc
rule("wdk.mc")

    -- add rule: wdk environment
    add_deps("wdk.env")

    -- set extensions
    set_extensions(".mc")

    -- before load
    on_load(function (target)

        -- imports
        import("core.project.config")

        -- get arch
        local arch = assert(config.arch(), "arch not found!")

        -- get wdk
        local wdk = target:data("wdk")

        -- get mc
        local mc = path.join(wdk.bindir, arch, is_host("windows") and "mc.exe" or "mc")
        if not os.isexec(mc) then
            mc = path.join(wdk.bindir, wdk.sdkver, arch, is_host("windows") and "mc.exe" or "mc")
        end

        -- save mc
        target:data_set("wdk.mc", mc)
    end)

    -- before build file
    before_build_file(function (target, sourcefile, opt)

        -- imports
        import("core.base.option")
        import("core.theme.theme")
        import("core.project.depend")
        import("utils.progress")

        -- get mc
        local mc = target:data("wdk.mc")
        assert(mc and os.isexec(mc), "mc not found!")

        -- get output directory
        local outputdir = path.join(target:autogendir(), "rules", "wdk", "mc")

        -- init args
        local args = {}
        local flags = target:values("wdk.mc.flags", sourcefile)
        if flags then
            table.join2(args, flags)
        end
        table.insert(args, "-h")
        table.insert(args, outputdir)
        table.insert(args, "-r")
        table.insert(args, outputdir)
        table.insert(args, sourcefile)

        -- add includedirs
        target:add("includedirs", outputdir)

        -- add header file
        local header = target:values("wdk.mc.header", sourcefile)
        local headerfile = header and path.join(outputdir, header) or nil
        if headerfile then
            table.insert(args, "-z")
            table.insert(args, path.basename(headerfile))
        else
            headerfile = path.join(outputdir, path.basename(sourcefile) .. ".h")
        end

        -- need build this object?
        local dependfile = target:dependfile(headerfile)
        local dependinfo = target:is_rebuilt() and {} or (depend.load(dependfile) or {})
        if not depend.is_changed(dependinfo, {lastmtime = os.mtime(headerfile), values = args}) then
            return
        end

        -- trace progress info
        progress.show(opt.progress, "${color.build.object}compiling.wdk.mc %s", sourcefile)

        -- do message compile
        if not os.isdir(outputdir) then
            os.mkdir(outputdir)
        end
        os.vrunv(mc, args)

        -- update files and values to the dependent file
        dependinfo.files  = {sourcefile}
        dependinfo.values = args
        depend.save(dependinfo, dependfile)
    end)

