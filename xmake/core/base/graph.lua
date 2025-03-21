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
local table   = require("base/table")
local queue   = require("base/queue")
local object  = require("base/object")
local hashset = require("base/hashset")

-- define module
local graph = graph or object { _init = {"_directed"} } {true}
local edge = edge or object { _init = {"_from", "_to"} }

-- new edge, from -> to
function edge.new(from, to)
    return edge {from, to}
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

function edge:__tostring()
    return string.format("<edge:%s-%s>", self:from(), self:to())
end

-- clear graph
function graph:clear()
    self._vertices = {}
    self._edges = {}
    self._adjacent_edges = {}
    self._edges_map = {}

    -- clear partial topological sort state
    self:partial_topo_sort_reset()
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
        self._edges_map[v] = nil
        self._adjacent_edges[v] = nil
        -- remove the adjacent edge with this vertex in the other vertices
        if not self:is_directed() then
            for _, w in ipairs(self:vertices()) do
                local edges = self:adjacent_edges(w)
                if edges then
                    table.remove_if(edges, function (_, e)
                        if e:other(w) == v then
                            self._edges_map[w] = nil
                            return true
                        end
                    end)
                end
            end
        end

        -- reset partial topological sort state since graph structure changed
        self._partial_topo_dirty = true
    end
end

-- reset partial topological sort state
function graph:partial_topo_sort_reset()
    self._partial_topo_in_progress = false
    self._partial_topo_in_degree = nil
    self._partial_topo_queue = nil
    self._partial_topo_processed = nil
    self._partial_topo_has_cycle = nil
    self._partial_topo_remaining_count = nil
    self._partial_topo_non_zero_indegree_count = nil
    self._partial_topo_dirty = false
end

-- get next node in topological order
--
-- @param limit     the maximum number of nodes to return
-- @return          array of nodes with zero in-degree, empty when complete
-- @return          has_cycle indicates if a cycle was detected
--
-- e.g.
--
-- add_edge(a, b) -- a depend on b
-- add_edge(b, c) -- b depend on c
--
-- local node1, has_cycle = g:partial_topo_sort_next() -- return c
-- local node2, has_cycle = g:partial_topo_sort_next() -- return b
-- local node3, has_cycle = g:partial_topo_sort_next() -- return a
-- local node4, has_cycle = g:partial_topo_sort_next() -- return nil (empty, all done)
--
function graph:partial_topo_sort_next(limit)
    limit = limit or math.huge
    if not self:is_directed() then
        return nil, false
    end

    if self._partial_topo_dirty then
        self:partial_topo_sort_reset()
    end

    -- check if we already detected a cycle
    if self._partial_topo_has_cycle then
        return nil, true
    end

    -- initialize topological sort state if not already in progress
    if not self._partial_topo_in_progress then
        self:_partial_topo_sort_init()
        self._partial_topo_in_progress = true
        if self._partial_topo_has_cycle then
            return nil, true
        end
    end

    local node
    if self._partial_topo_queue:empty() then
        -- return empty node if queue is empty (all processed or cycle detected)
        local processed_count = self._partial_topo_processed:size()
        self._partial_topo_has_cycle = processed_count ~= #self:vertices()
        return nil, self._partial_topo_has_cycle
    else
        -- get one node with zero in-degree
        node = self._partial_topo_queue:pop()
        self._partial_topo_processed:insert(node)
        self._partial_topo_remaining_count = self._partial_topo_remaining_count - 1

        -- update in-degrees based on the nodes in this node
        local edges = self:adjacent_edges(node)
        if edges then
            for _, e in ipairs(edges) do
                if e:from() == node then
                    local w = e:to()
                    self._partial_topo_in_degree[w] = self._partial_topo_in_degree[w] - 1

                    -- update non-zero in-degree count
                    if self._partial_topo_in_degree[w] == 0 then
                        self._partial_topo_non_zero_indegree_count = self._partial_topo_non_zero_indegree_count - 1

                        -- if in-degree becomes zero, add to queue for next node
                        if not self._partial_topo_processed:has(w) then
                            self._partial_topo_queue:push(w)
                        end
                    end
                end
            end
        end
    end

    -- early cycle detection - if all remaining nodes have in-degree > 0
    if self:_check_cycle_in_remaining() then
        return node, true
    end

    -- if queue is empty but we still have unprocessed nodes, we have a cycle
    if self._partial_topo_queue:empty() then
        local processed_count = self._partial_topo_processed:size()
        if processed_count ~= #self:vertices() then
            self._partial_topo_has_cycle = true
        end
    end

    return node, self._partial_topo_has_cycle
end

-- topological sort, use kahn's algorithm
--
-- e.g.
--
-- add_edge(a, b) -- a depend on b
-- add_edge(b, c) -- b depend on c
--
-- it will return {c, b, a}
function graph:topo_sort()
    if not self:is_directed() then
        return
    end

    -- calculate in-degree for each vertex
    local in_degree = {}
    for _, v in ipairs(self:vertices()) do
        in_degree[v] = 0
    end

    -- count incoming edges for each vertex
    for _, v in ipairs(self:vertices()) do
        local edges = self:adjacent_edges(v)
        if edges then
            for _, e in ipairs(edges) do
                if e:from() == v then
                    local w = e:to()
                    in_degree[w] = (in_degree[w] or 0) + 1
                end
            end
        end
    end

    -- queue of vertices with no incoming edges (no dependencies)
    local queue = queue.new()
    for _, v in ipairs(self:vertices()) do
        if in_degree[v] == 0 then
            queue:push(v)
        end
    end

    -- process queue
    local order_vertices = {}
    while not queue:empty() do
        -- remove a vertex with no incoming edges
        local v = queue:pop()
        table.insert(order_vertices, v)

        -- for each outgoing edge, remove it and update in-degrees
        local edges = self:adjacent_edges(v)
        if edges then
            for _, e in ipairs(edges) do
                if e:from() == v then
                    local w = e:to()
                    in_degree[w] = in_degree[w] - 1
                    -- if in-degree becomes zero, add to queue
                    if in_degree[w] == 0 then
                        queue:push(w)
                    end
                end
            end
        end
    end

    -- if we couldn't process all vertices, there must be a cycle
    local has_cycle = #order_vertices ~= #self:vertices()

    return order_vertices, has_cycle
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
function graph:add_edge(from, to)
    local e = edge.new(from, to)
    if not self:has_vertex(from) then
        table.insert(self._vertices, from)
        self._adjacent_edges[from] = {}
    end
    if not self:has_vertex(to) then
        table.insert(self._vertices, to)
        self._adjacent_edges[to] = {}
    end
    local edges_map = self._edges_map
    edges_map[from] = edges_map[from] or {}
    edges_map[from][to] = true
    if self:is_directed() then
        table.insert(self._adjacent_edges[from], e)
    else
        table.insert(self._adjacent_edges[from], e)
        table.insert(self._adjacent_edges[to], e)
        edges_map[to] = edges_map[to] or {}
        edges_map[to][from] = true
    end
    table.insert(self._edges, e)

    -- reset partial topological sort state since graph structure changed
    self._partial_topo_dirty = true
end

-- has the given edge?
function graph:has_edge(from, to)
    local edges = self:adjacent_edges(from)
    if edges then
        local edges_map = self._edges_map
        local from_map = edges_map[from]
        if from_map and from_map[to] then
            return true
        else
            for _, e in ipairs(edges) do
                if e:to() == to then
                    return true
                end
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
                gh:add_edge(e:from(), e:to())
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
                gh:add_edge(e:to(), e:from())
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

-- initialize topological sort state if not already in progress
function graph:_partial_topo_sort_init()

    -- calculate in-degree for each vertex
    self._partial_topo_in_degree = {}
    for _, v in ipairs(self:vertices()) do
        self._partial_topo_in_degree[v] = 0
    end

    -- count incoming edges for each vertex
    for _, v in ipairs(self:vertices()) do
        local edges = self:adjacent_edges(v)
        if edges then
            for _, e in ipairs(edges) do
                if e:from() == v then
                    local w = e:to()
                    self._partial_topo_in_degree[w] = (self._partial_topo_in_degree[w] or 0) + 1
                end
            end
        end
    end

    -- initialize queue with vertices that have no incoming edges
    self._partial_topo_queue = queue.new()
    for _, v in ipairs(self:vertices()) do
        if self._partial_topo_in_degree[v] == 0 then
            self._partial_topo_queue:push(v)
        end
    end

    -- track processed vertices
    self._partial_topo_processed = hashset.new()

    -- track counts for efficient cycle detection
    self._partial_topo_remaining_count = #self:vertices()
    self._partial_topo_non_zero_indegree_count = self._partial_topo_remaining_count - self._partial_topo_queue:size()

    -- quick cycle detection: if no nodes have zero in-degree, we have a cycle
    if self._partial_topo_queue:empty() and self._partial_topo_remaining_count > 0 then
        self._partial_topo_has_cycle = true
    end
end

-- check if there's a cycle in the remaining unprocessed nodes
function graph:_check_cycle_in_remaining()
    -- if all remaining nodes have in-degree > 0, we have a cycle
    if self._partial_topo_remaining_count > 0 and self._partial_topo_remaining_count == self._partial_topo_non_zero_indegree_count then
        self._partial_topo_has_cycle = true
        return true
    end
    return false
end

-- new graph
function graph.new(directed)
    local gh = graph {directed}
    gh:clear()
    return gh
end

-- return module: graph
return graph
