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
        import("core.platform.platform")

        -- need generate symbols?
        local strip = target:get("strip")
        local symbols = table.wrap(target:get("symbols"))
        if table.contains(symbols, "debug") and (strip == "all" or strip == "debug")
            and (target:is_binary() or target:is_shared()) and target:tool("strip") then -- only for strip command
            target:data_set("utils.symbols.extract", true)
            target:set("strip", "none") -- disable strip in link stage, because we need to run separate strip commands
            target:data_set("strip.origin", strip)
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

        -- get dsymutil and objcopy
        local dsymutil, objcopy
        if target:is_plat("macosx", "iphoneos", "watchos") then
            dsymutil = target:tool("dsymutil")
            if not dsymutil then
                return
            end
        else
            objcopy = target:tool("objcopy")
        end

        -- @note we use dependfile(targetfile) as sourcefile/mtime instead of targetfile to ensure it's mtime less than mtime(symbolfile), because targetfile will be changed after stripping
        local targetfile = target:targetfile()
        local symbolfile = target:symbolfile()
        local dryrun = option.get("dry-run")
        depend.on_changed(function ()

            -- trace progress info
            progress.show(opt.progress, "${color.build.target}generating.$(mode) %s", path.filename(symbolfile))

            -- we remove the previous symbol file to ensure that it will be re-generated and it's mtime will be changed.
            if not dryrun then
                os.tryrm(symbolfile)
            end

            -- generate symbols file
            if dsymutil then
                local dsymutil_argv = {}
                local arch = target:arch()
                if arch then
                    table.insert(dsymutil_argv, "-arch")
                    table.insert(dsymutil_argv, arch)
                end
                table.insert(dsymutil_argv, targetfile)
                table.insert(dsymutil_argv, "-o")
                table.insert(dsymutil_argv, symbolfile)
                os.vrunv(dsymutil, dsymutil_argv, {dryrun = dryrun})
            else
                -- @see https://github.com/xmake-io/xmake/issues/4684
                if objcopy then
                    os.vrunv(objcopy, {"--only-keep-debug", targetfile, symbolfile}, {dryrun = dryrun})
                elseif not dryrun then
                    os.vcp(targetfile, symbolfile)
                end
            end

            -- strip it
            local strip_argv = {}
            if target:is_plat("macosx", "iphoneos", "watchos") then
                -- do not support `-s`, we can only strip debug symbols
                local arch = target:arch()
                if arch then
                    table.insert(strip_argv, "-arch")
                    table.insert(strip_argv, arch)
                end
                table.insert(strip_argv, "-S")
            else
                -- -s/--strip-all for gnu strip
                local strip = target:data("strip.origin")
                if strip == "debug" then
                    table.insert(strip_argv, "-S")
                else
                    table.insert(strip_argv, "-s")
                end
            end
            table.insert(strip_argv, targetfile)
            os.vrunv(strip, strip_argv, {dryrun = dryrun})

            -- attach symbolfile to targetfile
            if not target:is_plat("macosx", "iphoneos", "watchos") and objcopy then
                -- @see https://github.com/xmake-io/xmake/issues/4684
                os.vrunv(objcopy, {"--add-gnu-debuglink=" .. symbolfile, targetfile}, {dryrun = dryrun})
            end

        end, {dependfile = target:dependfile(symbolfile),
              files = target:dependfile(targetfile),
              changed = target:is_rebuilt(),
              dryrun = dryrun})
    end)

