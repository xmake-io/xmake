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
-- @file        bazel.lua
--

-- imports
import("core.base.option")
import("core.tool.toolchain")
import("lib.detect.find_tool")

-- get configs
function _get_configs(package, configs)
    local configs = configs or {}
    return configs
end

-- get the build environments
function buildenvs(package, opt)
end

-- build package
function build(package, configs, opt)
    opt = opt or {}
    local bazel = assert(find_tool("bazel"), "bazel not found!")
    local argv = {"build"}
    configs = _get_configs(package, configs)
    if configs then
        table.join2(argv, configs)
    end
    os.vrunv(bazel.program, argv, {envs = opt.envs or buildenvs(package, opt)})
end
