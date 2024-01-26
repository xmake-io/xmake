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
-- @file        armlink.lua
--

-- imports
import("core.base.option")
import("core.base.global")
import("core.project.policy")
import("utils.progress")

function init(self)
end

-- make the link flag
function nf_link(self, lib)
    return "lib" .. lib .. ".a"
end

-- make the syslink flag
function nf_syslink(self, lib)
    return nf_link(self, lib)
end

-- make the linkdir flag
function nf_linkdir(self, dir)
    return {"--userlibpath", dir}
end

-- make runtime flag
function nf_runtime(self, runtime)
    if runtime == "microlib" then
        return "--library_type=microlib"
    end
end

-- make the link arguments list
function linkargv(self, objectfiles, targetkind, targetfile, flags, opt)
    opt = opt or {}
    local argv = table.join("-o", targetfile, objectfiles, flags)
    if is_host("windows") and not opt.rawargs then
        argv = winos.cmdargv(argv, {escape = true})
        if #argv > 0 and argv[1] and argv[1]:startswith("@") then
            argv[1] = argv[1]:replace("@", "", {plain = true})
            table.insert(argv, 1, "--via")
        end
    end
    return self:program(), argv
end

-- link the target file
function link(self, objectfiles, targetkind, targetfile, flags, opt)
    opt = opt or {}
    try
    {
        function ()
            os.mkdir(path.directory(targetfile))
            local program, argv = linkargv(self, objectfiles, targetkind, targetfile, flags)
            return os.iorunv(program, argv)
        end,
        catch
        {
            function (errors)

                -- parse and strip errors
                local lines = errors and tostring(errors):split('\n', {plain = true}) or {}
                if not option.get("verbose") then

                    -- find the start line of error
                    local start = 0
                    for index, line in ipairs(lines) do
                        if line:find("error:", 1, true) or line:find("错误：", 1, true) then
                            start = index
                            break
                        end
                    end

                    -- get 16 lines of errors
                    if start > 0 then
                        lines = table.slice(lines, start, start + ((#lines - start > 16) and 16 or (#lines - start)))
                    end
                end

                -- raise errors
                local results = #lines > 0 and table.concat(lines, "\n") or ""
                if not option.get("verbose") then
                    results = results .. "\n  ${yellow}> in ${bright}" .. sourcefile
                end
                raise(results)
            end
        },
        finally
        {
            function (ok, outdata, errdata)

                -- show warnings?
                if ok and errdata and #errdata > 0 and policy.build_warnings(opt) then
                    local lines = errdata:split('\n', {plain = true})
                    if #lines > 0 then
                        if not option.get("diagnosis") then
                            lines = table.slice(lines, 1, (#lines > 16 and 16 or #lines))
                        end
                        local warnings = table.concat(lines, "\n")
                        if progress.showing_without_scroll() then
                            print("")
                        end
                        cprint("${color.warning}%s", warnings)
                    end
                end

                -- show echo output? e.g. --map data
                -- @see https://github.com/xmake-io/xmake/issues/4420
                if ok and outdata and #outdata > 0 and option.get("diagnosis") then
                    print(outdata)
                end
            end
        }
    }
end

