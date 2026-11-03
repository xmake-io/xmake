-- !A cross-platform build utility based on Lua
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
-- @author      24bit-xjkp
-- @file        aotstats.lua
--

-- imports
import("core.base.semver")
import("utils")
import("cachegen")

-- get the qmlaotstats tool and check the AOT statistics support
--
-- `qt.qml.aot_stats = nil` only enables the report when the SDK supports it, while
-- `qt.qml.aot_stats = true` requires it. The caller doesn't look up the tool when
-- `aot_stats = false` or when the AOT compilation itself is disabled.
--
-- @param setting       the module settings, used to resolve the auto/required modes
-- @param cachegen_tool the qmlcachegen tool, used to check the --dump-aot-stats support
function get_tool(target, setting, cachegen_tool)
    local detect_only = setting.aot_stats == nil
    local sdkver = semver.new(target:data("qt").sdkver)
    if sdkver:lt("6.8") then
        if detect_only then
            return
        end
        raise("qt.qml: qmlaotstats requires Qt >= 6.8, please disable it with {aot_stats = false}")
    end
    local tool = utils.find_sdk_tool(target, "qmlaotstats")
    if not tool then
        if detect_only then
            return
        end
        raise("qt.qml: qmlaotstats is not found")
    end
    -- --dump-aot-stats also requires --module-id, otherwise qmlcachegen exits with an error
    if not utils.has_tool_option(cachegen_tool, { "--dump-aot-stats", "--module-id=qt.qml" }) then
        if detect_only then
            return
        end
        raise("qt.qml: qmlcachegen(%s) does not support --dump-aot-stats", cachegen_tool.program)
    end
    return tool
end

-- get the generated AOT report files
function get_paths(target)
    local dir = utils.get_autogen_dir(target, "qmlcachegen")
    return {
        aotstats     = path.join(dir, target:name() .. ".aotstats"),
        aotstatstxt  = path.join(dir, target:name() .. ".aotstats.txt"),
        aotstatslist = path.join(dir, target:name() .. ".aotstatslist")
    }
end

-- generate the AOT report, called by `batchcmds:call()`
--
-- The sidecar files are only generated for the sources with AOT-able content, e.g. a
-- pure .js file has no sidecar, so only list the existing ones. If none exists, keep
-- the old report and don't call qmlaotstats with an empty list.
function _generate_report(tool, listfile, statsfile, txtfile, sidecars)
    local existing = {}
    for _, sidecar in ipairs(sidecars) do
        if os.isfile(sidecar) then
            table.insert(existing, sidecar)
        end
    end
    if #existing == 0 then
        return
    end
    os.mkdir(path.directory(listfile))
    io.writefile(listfile, table.concat(existing, "\n"))
    os.vrunv(tool, { "aggregate", listfile, statsfile })
    os.vrunv(tool, { "format", statsfile, txtfile })
end

-- aggregate and format the AOT compilation statistics
function add_report(target, setup, batchcmds, sourcefiles, opt)
    local tool = setup.tools.aotstats
    if not tool then
        return
    end
    local paths = setup.aotpaths
    -- only components produce stats, e.g. a pure .js file has no sidecar. The report
    -- is generated after qmlcachegen, so the sidecars of this build already exist.
    local sidecars = {}
    for _, sourcefile in ipairs(sourcefiles) do
        local sidecar = cachegen.get_output(target, sourcefile) .. ".aotstats"
        if os.isfile(sidecar) then
            table.insert(sidecars, sidecar)
        end
    end
    if #sidecars == 0 then
        return
    end
    batchcmds:show_progress(
        opt.progress, "${color.build.object}generating.qt.qml.aotstats %s", path.filename(paths.aotstats)
    )
    batchcmds:call(_generate_report, { tool.program, paths.aotstatslist, paths.aotstats, paths.aotstatstxt, sidecars })
    -- rebuild the report if any sidecar file has been regenerated
    batchcmds:add_depfiles(sidecars)
    batchcmds:add_depvalues(tool.program, paths.aotstatslist, paths.aotstats, paths.aotstatstxt)
    batchcmds:set_depmtime(os.mtime(paths.aotstats))
    batchcmds:set_depcache(target:dependfile(paths.aotstats))
end
