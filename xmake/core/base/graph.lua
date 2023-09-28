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
-- @file        graph.lua
--

-- load modules
local table = require("base/table")
local object = require("base/object")

-- define module
local graph = graph or object { _init = {"_directed"} } {true}

-- clear graph
function graph:clear()
    self._vertices_list = {}
    self._adjacent_list = {}
end

-- get vertices
function graph:vertices()
    return self._vertices_list
end

-- get adjacent vertices of the the given vertex
function graph:adjacent_vertices(v)
    return self._adjacent_list[v]
end

-- get the vertex at the given index
function graph:vertex(idx)
    return self:vertices()[idx]
end

-- has the given vertex?
function graph:has_vertex(v)
    return table.contains(self:vertices(), v)
end

-- remove the given vertex?
function graph:remove_vertex(v)
    -- TODO
end

-- get edges
function graph:edges()
end

-- add edge
function graph:add_edge(v, w, weight)
end

-- has the given edge?
function graph:has_edge(v, w)
end

-- reverse graph
function graph:reverse()
end

-- new graph
function graph.new(directed)
    local gh = graph {directed}
    gh:clear()
    return gh
end

-- return module: graph
return graph

