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
local edge = edge or object { _init = {"_from", "_to", "_weight"} }

-- new edge, from -> to
function edge.new(from, to, weight)
    return edge {from, to, weight or 1.0}
end

function edge:from()
    return self._from
end

function edge:to()
    return self._to
end

function edge:other(v)
    if v == self._from then
        return self._to
    else
        return self._from
    end
end

function edge:weight()
    return self._weight
end

-- clear graph
function graph:clear()
    self._vertices = {}
    self._edges = {}
    self._adjacent_edges = {}
end

-- is empty?
function graph:empty()
    return #self:vertices() == 0
end

-- is directed?
function graph:is_directed()
    return self._directed
end

-- get vertices
function graph:vertices()
    return self._vertices
end

-- get adjacent edges of the the given vertex
function graph:adjacent_edges(v)
    return self._adjacent_edges[v]
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
    local contains = false
    table.remove_if(self._vertices, function (_, item)
        if item == v then
            contains = true
            return true
        end
    end)
    if contains then
        self._adjacent_edges[v] = nil
        -- remove the adjacent edge with this vertex in the other vertices
        if not self:is_directed() then
            for _, w in ipairs(self:vertices()) do
                local edges = self:adjacent_edges(w)
                if edges then
                    table.remove_if(edges, function (_, e) return e:other(w) == v end)
                end
            end
        end
    end
end

-- topological sort
function graph:topological_sort()
    local visited = {}
    for _, v in ipairs(self:vertices()) do
        visited[v] = false
    end
    local order_vertices = {}
    local function dfs(v)
        visited[v] = true
        local edges = self:adjacent_edges(v)
        if edges then
            for _, e in ipairs(edges) do
                local w = e:other(v)
                if not visited[w] then
                    dfs(w)
                end
            end
        end
        table.insert(order_vertices, v)
    end
    for _, v in ipairs(self:vertices()) do
        if not visited[v] then
            dfs(v)
        end
    end
    return table.reverse(order_vertices)
end

-- find cycle
function graph:find_cycle()
    local visited = {}
    local stack = {}
    local cycle = {}

    local function dfs(v)
        visited[v] = true
        stack[v] = true
        table.insert(cycle, v)
        local edges = self:adjacent_edges(v)
        if edges then
            for _, e in ipairs(edges) do
                local w = e:other(v)
                if not visited[w] then
                    if dfs(w) then
                        return true
                    elseif stack[w] then
                        return true
                    end
                elseif stack[w] then
                    for i = #cycle, 1, -1 do
                        if cycle[i] == w then
                            cycle = table.slice(cycle, i)
                            return true
                        end
                    end
                end
            end
        end
        table.remove(cycle)
        stack[v] = false
        return false
    end

    for _, v in ipairs(self:vertices()) do
        if not visited[v] then
            if dfs(v) then
                return cycle
            end
        end
    end
end

-- get edges
function graph:edges()
    return self._edges
end

-- add edge
function graph:add_edge(from, to, weight)
    local e = edge.new(from, to, weight)
    if not self:has_vertex(from) then
        table.insert(self._vertices, from)
        self._adjacent_edges[from] = {}
    end
    if not self:has_vertex(to) then
        table.insert(self._vertices, to)
        self._adjacent_edges[to] = {}
    end
    if self:is_directed() then
        table.insert(self._adjacent_edges[e:from()], e)
    else
        table.insert(self._adjacent_edges[e:from()], e)
        table.insert(self._adjacent_edges[e:to()], e)
    end
    table.insert(self._edges, e)
end

-- has the given edge?
function graph:has_edge(from, to)
    local edges = self:adjacent_edges(from)
    if edges then
        for _, e in ipairs(edges) do
            if e:to() == to then
                return true
            end
        end
    end
    return false
end

-- clone graph
function graph:clone()
    local gh = graph.new(self:is_directed())
    for _, v in ipairs(self:vertices()) do
        local edges = self:adjacent_edges(v)
        if edges then
            for _, e in ipairs(edges) do
                gh:add_edge(e:from(), e:to(), e:weight())
            end
        end
    end
    return gh
end

-- reverse graph
function graph:reverse()
    if not self:is_directed() then
        return self:clone()
    end
    local gh = graph.new(self:is_directed())
    for _, v in ipairs(self:vertices()) do
        local edges = self:adjacent_edges(v)
        if edges then
            for _, e in ipairs(edges) do
                gh:add_edge(e:to(), e:from(), e:weight())
            end
        end
    end
    return gh
end

-- dump graph
function graph:dump()
    local vertices = self:vertices()
    local edges = self:edges()
    print(string.format("graph: %s, vertices: %d, edges: %d", self:is_directed() and "directed" or "not-directed", #vertices, #edges))
    print("vertices: ")
    for _, v in ipairs(vertices) do
        print(string.format("  %s", v))
    end
    print("")
    print("edges: ")
    for _, e in ipairs(edges) do
        print(string.format("  %s -> %s", e:from(), e:to()))
    end
end

-- new graph
function graph.new(directed)
    local gh = graph {directed}
    gh:clear()
    return gh
end

-- return module: graph
return graph

