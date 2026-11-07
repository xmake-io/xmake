import("async.jobgraph")
import("async.runjobs")

function test_failure_after_yield(t)
    local started = {}
    local finished = false
    t:will_raise(function ()
        runjobs("failure_after_yield", function (index)
            started[index] = true
            if index == 1 then
                os.sleep(10)
                raise("expected runjobs failure")
            end
            os.sleep(30)
            finished = true
        end, {total = 4, comax = 2})
    end, "expected runjobs failure")
    t:require(started[1] and started[2])
    t:require(finished)
    t:require_not(started[3] or started[4])
end

function test_failure_with_blocked_dependency(t)
    local jobs = jobgraph.new()
    local dependent_ran = false
    jobs:add("producer", function ()
        os.sleep(10)
        raise("expected producer failure")
    end)
    jobs:add("dependent", function ()
        dependent_ran = true
    end)
    jobs:add_orders("producer", "dependent")
    t:will_raise(function ()
        runjobs("failure_with_blocked_dependency", jobs, {comax = 2})
    end, "expected producer failure")
    t:require_not(dependent_ran)
end

function test_first_error_is_preserved(t)
    t:will_raise(function ()
        runjobs("first_error_is_preserved", function (index)
            os.sleep(index == 1 and 10 or 30)
            raise(index == 1 and "first runjobs failure" or "second runjobs failure")
        end, {total = 2, comax = 2})
    end, "first runjobs failure")
end

function test_success(t)
    local finished = 0
    runjobs("success", function ()
        os.sleep(1)
        finished = finished + 1
    end, {total = 4, comax = 2})
    t:are_equal(finished, 4)
end
