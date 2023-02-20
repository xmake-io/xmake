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
-- @file        devlink.lua
--

-- imports
import("core.base.option")
import("core.project.project")

-- https://github.com/xmake-io/xmake/issues/1976#issuecomment-1427378799
function _check_target(target, opt)
    if target:is_binary() then
        local sourcebatches = target:sourcebatches()
        if sourcebatches and not sourcebatches["cuda.build"] then
            for _, dep in ipairs(target:orderdeps()) do
                if dep:is_static() then
                    sourcebatches = dep:sourcebatches()
                    if sourcebatches and sourcebatches["cuda.build"] then
                        local devlink = dep:policy("build.cuda.devlink") or dep:values("cuda.build.devlink")
                        if not devlink then
                            wprint('target(%s)${clear}: cuda device link is not performed! specify set_policy("build.cuda.devlink", true) to enable it', dep:name())
                        end
                    end
                end
            end
        end
    end
end

function main(opt)
    if opt.target then
        _check_target(opt.target, opt)
    else
        for _, target in pairs(project.targets()) do
            _check_target(target, opt)
        end
    end
end

