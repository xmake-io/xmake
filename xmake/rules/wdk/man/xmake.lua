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

-- define rule: *.man
rule("wdk.man")

    -- add rule: wdk environment
    add_deps("wdk.env")

    -- set extensions
    set_extensions(".man")

    -- before load
    on_load(function (target)

        -- imports
        import("core.project.config")

        -- get arch
        local arch = assert(config.arch(), "arch not found!")

        -- get wdk
        local wdk = target:data("wdk")

        -- get ctrpp
        local ctrpp = path.join(wdk.bindir, arch, "ctrpp.exe")
        if not os.isexec(ctrpp) then
            ctrpp = path.join(wdk.bindir, wdk.sdkver, arch, "ctrpp.exe")
        end

        -- save ctrpp
        target:data_set("wdk.ctrpp", ctrpp)
    end)

    -- before build file
    before_build_file(function (target, sourcefile, opt)

        -- imports
        import("core.base.option")
        import("core.theme.theme")
        import("core.project.depend")
        import("utils.progress")

        -- get ctrpp
        local ctrpp = target:data("wdk.ctrpp")
        assert(ctrpp and os.isexec(ctrpp), "ctrpp not found!")

        -- get output directory
        local outputdir = path.join(target:autogendir(), "rules", "wdk", "man")

        -- init args
        local args = {sourcefile}
        local flags = target:values("wdk.man.flags", sourcefile)
        if flags then
            table.join2(args, flags)
        end

        -- add includedirs
        target:add("includedirs", outputdir)

        -- add header file
        local header = target:values("wdk.man.header", sourcefile)
        local headerfile = header and path.join(outputdir, header) or nil
        if headerfile then
            table.insert(args, "-o")
            table.insert(args, headerfile)
        else
            raise("please call `set_values(\"wdk.man.header\", \"header.h\")` to set the provider header file name!")
        end

        -- add prefix
        local prefix = target:values("wdk.man.prefix", sourcefile)
        if prefix then
            table.insert(args, "-prefix")
            table.insert(args, prefix)
        end

        -- add counter header file
        local counter_header = target:values("wdk.man.counter_header", sourcefile)
        local counter_headerfile = counter_header and path.join(outputdir, counter_header) or nil
        if counter_headerfile then
            table.insert(args, "-ch")
            table.insert(args, counter_headerfile)
        end

        -- add resource file
        local resource = target:values("wdk.man.resource", sourcefile)
        local resourcefile = resource and path.join(outputdir, resource) or nil
        if resourcefile then
            table.insert(args, "-rc")
            table.insert(args, resourcefile)
        end

        -- need build this object?
        local dependfile = target:dependfile(headerfile)
        local dependinfo = target:is_rebuilt() and {} or (depend.load(dependfile) or {})
        if not depend.is_changed(dependinfo, {lastmtime = os.mtime(headerfile), values = args}) then
            return
        end

        -- trace progress info
        progress.show(opt.progress, "${color.build.object}compiling.wdk.man %s", sourcefile)

        -- generate header and resource file
        if not os.isdir(outputdir) then
            os.mkdir(outputdir)
        end
        os.vrunv(ctrpp, args)

        if target:has_tool("cxx", "clang", "clangxx") then
            if resourcefile and os.isfile(resourcefile) then
                local content = io.readfile(resourcefile)
                io.writefile(resourcefile, content, {encoding = "utf8"})
            end
        end

        -- update files and values to the dependent file
        dependinfo.files  = {sourcefile}
        dependinfo.values = args
        depend.save(dependinfo, dependfile)
    end)

