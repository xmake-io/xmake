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
-- @file        start_service.lua
--

-- imports
import("core.base.option")
import("core.project.project")
import("private.service.server_config", {alias = "config"})
import("private.service.service")

function main(opt)

    -- start service
    opt = opt or {}
    if opt.daemon then
        local argv = {"lua"}
        if option.get("verbose") then
            table.insert(argv, "-v")
        end
        if option.get("diagnosis") then
            table.insert(argv, "-D")
        end
        table.insert(argv, "private.service.service")
        table.insert(argv, "--daemon")
        local logfile = config.get("logfile")
        if logfile then
            local logdir = path.directory(logfile)
            if not os.isdir(logdir) then
                os.mkdir(logdir)
            end
        end
        local tmpdir = os.tmpfile() .. ".dir"
        if not os.isdir(tmpdir) then
            os.mkdir(tmpdir)
        end
        try
        {
            function()
                os.execv(os.programfile(), argv, {detach = true, curdir = tmpdir, stdout = logfile, stderr = logfile})
            end,
            catch
            {
                function (errors)
                    io.cat(logfile)
                    raise(errors)
                end
            }
        }
    else
        service()
    end
end

