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

-- define rule: utils.symbols.extract
rule("utils.symbols.extract")
    before_link(function(target)

        -- imports
        import("core.platform.platform")

        -- need generate symbols?
        local strip = target:get("strip")
        local targetkind = target:kind()
        if target:get("symbols") == "debug" and (strip == "all" or strip == "debug")
            and (targetkind == "binary" or targetkind == "shared") and platform.tool("strip") then -- only for strip command
            target:data_set("utils.symbols.extract", true)
            target:set("strip", "none") -- disable strip in link stage, because we need to run separate strip commands
        end
    end)
    after_link(function (target, opt)

        -- need generate symbols?
        if not target:data("utils.symbols.extract") then
            return
        end

        -- imports
        import("core.base.option")
        import("core.theme.theme")
        import("core.project.depend")
        import("core.platform.platform")
        import("utils.progress")

        -- get strip
        local strip = target:tool("strip")
        if not strip then
            return
        end

        -- get dsymutil
        local dsymutil
        if is_plat("macosx", "iphoneos", "watchos") then
            dsymutil = target:tool("dsymutil")
            if not dsymutil then
                return
            end
        end

        -- need re-generate this symbol file?
        local symbolfile = target:symbolfile()
        local targetfile = target:targetfile()
        local dependfile = target:dependfile(symbolfile)
        local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})
        if not depend.is_changed(dependinfo, {lastmtime = os.mtime(dependfile)}) then
            return
        end

        -- trace progress info
        progress.show(opt.progress, "${color.build.target}generating.$(mode) %s", path.filename(symbolfile))

        -- we remove the previous symbol file to ensure that it will be re-generated and it's mtime will be changed.
        local dryrun = option.get("dry-run")
        if not dryrun then
            os.tryrm(symbolfile)
        end

        -- generate symbols file
        if dsymutil then
            local dsymutil_argv = {}
            local arch = get_config("arch")
            if arch then
                table.insert(dsymutil_argv, "-arch")
                table.insert(dsymutil_argv, arch)
            end
            table.insert(dsymutil_argv, targetfile)
            table.insert(dsymutil_argv, "-o")
            table.insert(dsymutil_argv, symbolfile)
            os.vrunv(dsymutil, dsymutil_argv, {dryrun = dryrun})
        elseif not dryrun then
            os.vcp(targetfile, symbolfile)
        end

        -- strip it
        local strip_argv = {}
        if is_plat("macosx", "iphoneos", "watchos") then
            -- do not support `-s`, we can only strip debug symbols
            local arch = get_config("arch")
            if arch then
                table.insert(strip_argv, "-arch")
                table.insert(strip_argv, arch)
            end
            table.insert(strip_argv, "-S")
        else
            -- -s/--strip-all for gnu strip
            table.insert(strip_argv, "-s")
        end
        table.insert(strip_argv, targetfile)
        os.vrunv(strip, strip_argv, {dryrun = dryrun})

        -- update files and values to the dependent file
        -- @note we use dependfile(targetfile) as sourcefile/mtime instead of targetfile to ensure it's mtime less than mtime(symbolfile), because targetfile will be changed after stripping
        dependinfo.files  = {target:dependfile(targetfile)}
        depend.save(dependinfo, dependfile)
    end)

