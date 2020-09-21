import("core.base.json")

-- test decode
function test_json_decode(t)
    t:are_equal(json.decode('{}'), {})
    t:are_equal(json.decode('[]'), {})
    t:are_equal(json.decode('{"a":1, "b":"2", "c":true, "d":false, "e":null, "f":[]}'), {a = 1, b = "2", c = true, d = false, e = json.null, f = {}})
    t:are_equal(json.decode('{"a":[], "b":[1,2], "c":{"a":1}}'), {a = {}, b = {1,2}, c = {a = 1}})
    t:are_equal(json.decode('[1,"2"]'), {1, "2"})
    t:are_equal(json.decode('[1,"2", {"a":1, "b":true}]'), {1, "2", {a = 1, b = true}})
end

-- test encode
function test_json_encode(t)
    t:are_equal(json.encode({}), '{}')
    t:are_equal(json.encode({}), '{}')
    t:are_equal(json.encode({json.null, 1, "2", false, true}), '[null,1,"2",false,true]')
    t:are_equal(json.encode({1, "2", {a = 1}}), '[1,"2",{"a":1}]')
    t:are_equal(json.encode({1, "2", {b = true}}), '[1,"2",{"b":true}]')
end
