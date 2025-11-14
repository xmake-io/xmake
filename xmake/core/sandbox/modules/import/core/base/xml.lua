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
-- @file        xml.lua
--

-- define module
local sandbox_core_base_xml = sandbox_core_base_xml or {}

-- load modules
local xml       = require("base/xml")
local raise     = require("sandbox/modules/raise")

-- inherit some builtin interfaces
sandbox_core_base_xml.encode   = xml.encode
sandbox_core_base_xml.find     = xml.find
sandbox_core_base_xml.text_of  = xml.text_of
sandbox_core_base_xml.text     = xml.text
sandbox_core_base_xml.new      = xml.new
sandbox_core_base_xml.empty    = xml.empty
sandbox_core_base_xml.comment  = xml.comment
sandbox_core_base_xml.cdata    = xml.cdata
sandbox_core_base_xml.doctype  = xml.doctype

-- decode xml data
function sandbox_core_base_xml.decode(data, opt)
    local node, errors = xml.decode(data, opt)
    if not node then
        raise(errors)
    end
    return node
end

-- load xml file to the lua table
function sandbox_core_base_xml.load(filepath, opt)
    local node, errors = xml.load(filepath, opt)
    if not node then
        raise(errors)
    end
    return node
end

-- save xml node to the file
function sandbox_core_base_xml.save(filepath, node, opt)
    local ok, errors = xml.save(filepath, node, opt)
    if not ok then
        raise(errors)
    end
    return ok
end

-- return module
return sandbox_core_base_xml

