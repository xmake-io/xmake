import("core.base.graph")
import("async.jobgraph")
import("lib.lua.pcall")

local function new_graph(vertices, edges)
    local g = graph.new(true)
    for _, vertex in ipairs(vertices) do
        g:add_vertex(vertex)
    end
    for _, edge in ipairs(edges) do
        g:add_edge(edge[1], edge[2])
    end
    return g
end

local function initial_cycle(edges)
    local g = new_graph({}, edges)
    local node, has_cycle = g:partial_topo_sort_next()
    return node == nil and has_cycle == true,
           "node=" .. tostring(node) .. ",cycle=" .. tostring(has_cycle)
end

local function new_jobs(names, orders)
    local jobs = jobgraph.new("partial-cycle-boundary")
    for _, name in ipairs(names) do
        jobs:add(name, function () end)
    end
    for _, order in ipairs(orders) do
        jobs:add_orders(table.unpack(order))
    end
    return jobs:build()
end

local function job_cycle(names, orders)
    local queue = new_jobs(names, orders)
    local ok, result = pcall(function () return queue:getfree() end)
    local message = tostring(result)
    return not ok and message:find("circular job dependency detected!", 1, true) ~= nil,
           "ok=" .. tostring(ok) .. ",result=" .. message
end

function test_partial_cycle_boundaries(t)
    local cases = {
        {name = "self_cycle", target = true, run = function ()
            return initial_cycle({{"a", "a"}})
        end},
        {name = "two_vertex_cycle", target = true, run = function ()
            return initial_cycle({{"a", "b"}, {"b", "a"}})
        end},
        {name = "three_vertex_cycle", target = true, run = function ()
            return initial_cycle({{"a", "b"}, {"b", "c"}, {"c", "a"}})
        end},
        {name = "job_mutual_dependency_error", target = true, run = function ()
            return job_cycle({"a", "b"}, {{"a", "b"}, {"b", "a"}})
        end},
        {name = "job_self_dependency_error", target = true, run = function ()
            return job_cycle({"a"}, {{"a", "a"}})
        end},
        {name = "empty_graph", run = function ()
            local g = new_graph({}, {})
            local node, has_cycle = g:partial_topo_sort_next()
            return node == nil and not has_cycle, "cycle=" .. tostring(has_cycle)
        end},
        {name = "isolated_vertex", run = function ()
            local g = new_graph({"only"}, {})
            local node, has_cycle = g:partial_topo_sort_next()
            if node ~= "only" or has_cycle then
                return false, "first=" .. tostring(node)
            end
            g:partial_topo_sort_remove(node)
            node, has_cycle = g:partial_topo_sort_next()
            return node == nil and not has_cycle, "completed=" .. tostring(node)
        end},
        {name = "linear_graph", run = function ()
            local g = new_graph({}, {{"a", "b"}, {"b", "c"}})
            for _, expected in ipairs({"a", "b", "c"}) do
                local node, has_cycle = g:partial_topo_sort_next()
                if node ~= expected or has_cycle then
                    return false, "expected=" .. expected .. ",actual=" .. tostring(node)
                end
                g:partial_topo_sort_remove(node)
            end
            local node, has_cycle = g:partial_topo_sort_next()
            return node == nil and not has_cycle, "completed=" .. tostring(node)
        end},
        {name = "waiting_for_predecessor", run = function ()
            local g = new_graph({}, {{"a", "b"}})
            local first, has_cycle = g:partial_topo_sort_next()
            local waiting, waiting_cycle = g:partial_topo_sort_next()
            if first ~= "a" or has_cycle or waiting ~= nil or waiting_cycle then
                return false, "waiting_cycle=" .. tostring(waiting_cycle)
            end
            g:partial_topo_sort_remove(first)
            local nextnode, nextcycle = g:partial_topo_sort_next()
            return nextnode == "b" and not nextcycle, "released=" .. tostring(nextnode)
        end},
        {name = "two_independent_jobs_in_flight", run = function ()
            local g = new_graph({"a", "b"}, {})
            local first, first_cycle = g:partial_topo_sort_next()
            local second, second_cycle = g:partial_topo_sort_next()
            local waiting, waiting_cycle = g:partial_topo_sort_next()
            local both = (first == "a" and second == "b") or (first == "b" and second == "a")
            if not both or first_cycle or second_cycle or waiting ~= nil or waiting_cycle then
                return false, "waiting_cycle=" .. tostring(waiting_cycle)
            end
            g:partial_topo_sort_remove(first)
            waiting, waiting_cycle = g:partial_topo_sort_next()
            if waiting ~= nil or waiting_cycle then
                return false, "one_pending_cycle=" .. tostring(waiting_cycle)
            end
            g:partial_topo_sort_remove(second)
            local node, has_cycle = g:partial_topo_sort_next()
            return node == nil and not has_cycle, "completed=" .. tostring(node)
        end},
        {name = "cycle_after_ready_component", run = function ()
            local g = new_graph({}, {{"a", "b"}, {"c", "d"}, {"d", "c"}})
            for _, expected in ipairs({"a", "b"}) do
                local node, has_cycle = g:partial_topo_sort_next()
                if node ~= expected or has_cycle then
                    return false, "expected=" .. expected .. ",actual=" .. tostring(node)
                end
                g:partial_topo_sort_remove(node)
            end
            local node, has_cycle = g:partial_topo_sort_next()
            return node == nil and has_cycle == true, "cycle=" .. tostring(has_cycle)
        end},
        {name = "linear_job_queue_and_waiting", run = function ()
            local queue = new_jobs({"a", "b", "c"}, {{"a", "b", "c"}})
            for _, expected in ipairs({"a", "b", "c"}) do
                local job = queue:getfree()
                if not job or job.name ~= expected then
                    return false, "expected_job=" .. expected
                end
                if queue:getfree() ~= nil then
                    return false, "dependent job released before completion"
                end
                queue:remove(job)
            end
            return queue:getfree() == nil, "all jobs completed"
        end}
    }

    local passed, target_failed, control_failed = 0, 0, 0
    local failures = {}
    for _, case in ipairs(cases) do
        local ok, matched, detail = pcall(case.run)
        if ok and matched then
            passed = passed + 1
            print("BOUNDARY_CASE_PASS " .. case.name)
        else
            failures[#failures + 1] = case.name
            if case.target then
                target_failed = target_failed + 1
            else
                control_failed = control_failed + 1
            end
            print("BOUNDARY_CASE_FAIL " .. case.name .. " " .. tostring(ok and detail or matched))
        end
    end
    print(string.format("BOUNDARY_SUMMARY cases=%d pass=%d target_fail=%d control_fail=%d", #cases, passed, target_failed, control_failed))
    t:require(#failures == 0, "partial topological sort failures: " .. table.concat(failures, ", "))
end
