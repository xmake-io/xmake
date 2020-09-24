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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        linker.lua
--

-- define module
local sandbox_core_tool_linker = sandbox_core_tool_linker or {}

-- load modules
local platform  = require("platform/platform")
local linker    = require("tool/linker")
local raise     = require("sandbox/modules/raise")

-- load the linker from the given target kind
function sandbox_core_tool_linker.load(targetkind, sourcekinds, opt)

    -- get the linker instance
    local instance, errors = linker.load(targetkind, sourcekinds, opt and opt.target or nil)
    if not instance then
        raise(errors)
    end

    -- ok
    return instance
end

-- make command for linking target file
function sandbox_core_tool_linker.linkcmd(targetkind, sourcekinds, objectfiles, targetfile, opt)
    return os.args(table.join(sandbox_core_tool_linker.linkargv(targetkind, sourcekinds, objectfiles, targetfile, opt)))
end

-- make arguments list for linking target file
function sandbox_core_tool_linker.linkargv(targetkind, sourcekinds, objectfiles, targetfile, opt)

    -- init options
    opt = opt or {}

    -- get the linker instance
    local instance = sandbox_core_tool_linker.load(targetkind, sourcekinds, opt)

    -- make arguments list
    return instance:linkargv(objectfiles, targetfile, opt)
end

-- make link flags for the given target
--
-- @param targetkind    the target kind
-- @param sourcekinds   the source kinds
-- @param opt           the argument options (contain all the linker attributes of target),
--                      e.g. {target = ..., targetkind = "static", config = {cxflags = "", defines = "", includedirs = "", ...}}
--
function sandbox_core_tool_linker.linkflags(targetkind, sourcekinds, opt)

    -- init options
    opt = opt or {}

    -- get the linker instance
    local instance = sandbox_core_tool_linker.load(targetkind, sourcekinds, opt)

    -- make flags
    return instance:linkflags(opt)
end

-- link target file
function sandbox_core_tool_linker.link(targetkind, sourcekinds, objectfiles, targetfile, opt)

    -- init options
    opt = opt or {}

    -- get the linker instance
    local instance = sandbox_core_tool_linker.load(targetkind, sourcekinds, opt)

    -- link it
    local ok, errors = instance:link(objectfiles, targetfile, opt)
    if not ok then
        raise(errors)
    end
end

-- has the given flags?
--
-- @param targetkind    the target kind
-- @param sourcekinds   the source kinds
-- @param flags         the flags
-- @param opt           the options
--
-- @return              the supported flags or nil
--
function sandbox_core_tool_linker.has_flags(targetkind, sourcekinds, flags, opt)

    -- init options
    opt = opt or {}

    -- get the linker instance
    local instance = sandbox_core_tool_linker.load(targetkind, sourcekinds, opt)

    -- has flags?
    return instance:has_flags(flags)
end

-- return module
return sandbox_core_tool_linker
