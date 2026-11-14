import("async.jobgraph")

local function dummy_job() end

function test_group_bridge_reuse(t)
    local jobs = jobgraph.new()
    jobs:group("foo", function ()
        jobs:add("foo/1", dummy_job)
        jobs:add("foo/2", dummy_job)
    end)
    jobs:group("bar", function ()
        jobs:add("bar/1", dummy_job)
    end)
    jobs:add_orders("foo", "bar")
    local vertices_before = #jobs._dag:vertices()
    jobs:add_orders("foo", "bar")
    local vertices_after = #jobs._dag:vertices()
    t:are_equal(vertices_before, vertices_after)
end

function test_group_bridge_updates_with_new_job(t)
    local jobs = jobgraph.new()
    jobs:group("foo", function ()
        jobs:add("foo/1", dummy_job)
    end)
    jobs:group("bar", function ()
        jobs:add("bar/1", dummy_job)
    end)
    jobs:add_orders("foo", "bar")
    jobs:group("foo", function ()
        jobs:add("foo/2", dummy_job)
    end)

    local queue = jobs:build()
    local first = queue:getfree()
    t:require(first.name == "foo/1" or first.name == "foo/2")
    queue:remove(first)
    local second = queue:getfree()
    t:require(second.name == "foo/1" or second.name == "foo/2")
    t:require(second.name ~= first.name)
    queue:remove(second)
    local third = queue:getfree()
    t:are_equal(third.name, "bar/1")
end


function _check_fence(t, names, deps)
    local jobs = jobgraph.new()
    local running = 0
    local maximum = 0
    local exclusive = false
    local finished = {}
    for _, name in ipairs(names) do
        local fence = name:startswith("fence")
        jobs:add(name, function ()
            assert(not exclusive, name .. " overlaps an exclusive job")
            if fence then
                assert(running == 0, name .. " overlaps a running job")
                exclusive = true
            end
            for _, dep in ipairs(deps and deps[name]) do
                assert(finished[dep], name .. " started before " .. dep)
            end
            running = running + 1
            maximum = math.max(maximum, running)
            os.sleep(10)
            running = running - 1
            exclusive = false
            finished[name] = true
        end, {fence = fence})
    end
    for name, before in pairs(deps) do
        for _, dep in ipairs(before) do
            jobs:add_orders(dep, name)
        end
    end
    import("async.runjobs")("jobgraph_fence", jobs, {comax = 4})
    t:are_equal(running, 0)
    t:are_equal(#table.keys(finished), #names)
    return maximum
end

function test_fence(t)
    t:are_equal(_check_fence(t, {"a", "b", "c", "d", "e"}), 4)
    _check_fence(t, {"fence_first", "a", "b", "c", "d"})
    _check_fence(t, {"a", "b", "fence_middle", "c", "d"})
    _check_fence(t, {"a", "b", "c", "d", "fence_last"})
    t:are_equal(_check_fence(t, {"fence_a", "fence_b", "fence_c"}), 1)
    _check_fence(t, {"a", "b", "fence_a", "c", "fence_b", "d"}, {
        fence_a = {"a", "b"}, c = {"fence_a"}, fence_b = {"c"}, d = {"fence_b"}
    })
end

function test_fence_failure(t)
    import("async.runjobs")
    for _, fail_fence in ipairs({false, true}) do
        local jobs = jobgraph.new()
        local after_ran = false
        jobs:add("before", function ()
            os.sleep(10)
            if not fail_fence then
                raise("expected parallel job failure")
            end
        end)
        jobs:add("exclusive", function ()
            os.sleep(10)
            if fail_fence then
                raise("expected exclusive job failure")
            end
        end, {fence = true})
        jobs:add("after", function ()
            after_ran = true
        end)
        t:will_raise(function ()
            runjobs("jobgraph_fence_failure", jobs, {comax = 4})
        end, fail_fence and "expected exclusive job failure" or "expected parallel job failure")
        t:require_not(after_ran)
    end
end
