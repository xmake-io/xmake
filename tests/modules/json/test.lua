import("core.base.json")

local json_null = json.null
local json_pure_null = json.purenull

function json_decode(jsonstr)
    return json.decode(jsonstr)
end

function json_encode(luatable)
    return json.encode(luatable)
end

function json_pure_decode(jsonstr)
    return json.decode(jsonstr, {pure = true})
end

function json_pure_encode(luatable)
    return json.encode(luatable, {pure = true})
end

function test_json_decode(t)
    t:are_equal(json_decode('{}'), {})
    t:are_equal(json_decode('[]'), {})
    t:are_equal(json.is_marked_as_array(json_decode('[]')), true)
    t:are_equal(not json.is_marked_as_array(json_decode('{}')), true)
    t:are_equal(json_decode('{"a":1, "b":"2", "c":true, "d":false, "e":null, "f":[]}'), {a = 1, b = "2", c = true, d = false, e = json_null, f = {}})
    t:are_equal(json_decode('{"a":[], "b":[1,2], "c":{"a":1}}'), {a = {}, b = {1,2}, c = {a = 1}})
    t:are_equal(json_decode('[1,"2"]'), {1, "2"})
    t:are_equal(json_decode('[1,"2", {"a":1, "b":true}]'), {1, "2", {a = 1, b = true}})
    t:are_equal(json_decode('[1,0xa,0xdeadbeef, 0xffffffff,-1]'), {1, 0xa, 0xdeadbeef, 0xffffffff, -1})
end

function test_json_encode(t)
    t:are_equal(json_encode({}), '{}')
    t:are_equal(json_encode(json.mark_as_array({})), '[]')
    t:are_equal(json_encode({json_null, 1, "2", false, true}), '[null,1,"2",false,true]')
    t:are_equal(json_encode({1, "2", {a = 1}}), '[1,"2",{"a":1}]')
    t:are_equal(json_encode({1, "2", {b = true}}), '[1,"2",{"b":true}]')
    t:are_equal(json_encode(json.mark_as_array({1, 0xa, 0xdeadbeef, 0xffffffff, -1})), '[1,10,3735928559,4294967295,-1]')
    local pretty_expected = table.concat({
        "{",
        "    \"name\": \"xmake\",",
        "    \"targets\": [",
        "        \"foo\",",
        "        \"bar\"",
        "    ]",
        "}"
    }, "\n")
    t:are_equal(json_encode({name = "xmake", targets = {"foo", "bar"}}, {pretty = true, indent = 4}), pretty_expected)
end

function test_pure_json_decode(t)
    t:are_equal(json_pure_decode('{}'), {})
    t:are_equal(json_pure_decode('[]'), {})
    t:are_equal(json.is_marked_as_array(json_pure_decode('[]')), true)
    t:are_equal(not json.is_marked_as_array(json_pure_decode('{}')), true)
    t:are_equal(json_pure_decode('{"a":1, "b":"2", "c":true, "d":false, "e":null, "f":[]}'), {a = 1, b = "2", c = true, d = false, e = json_pure_null, f = {}})
    t:are_equal(json_pure_decode('{"a":[], "b":[1,2], "c":{"a":1}}'), {a = {}, b = {1,2}, c = {a = 1}})
    t:are_equal(json_pure_decode('[1,"2"]'), {1, "2"})
    t:are_equal(json_pure_decode('[1,"2", {"a":1, "b":true}]'), {1, "2", {a = 1, b = true}})
    t:are_equal(json_pure_decode('[1,0xa,0xdeadbeef, 0xffffffff,-1]'), {1, 0xa, 0xdeadbeef, 0xffffffff, -1})
end

function test_pure_json_encode(t)
    t:are_equal(json_pure_encode({}), '{}')
    t:are_equal(json_pure_encode(json.mark_as_array({})), '[]')
    t:are_equal(json_pure_encode({json_pure_null, 1, "2", false, true}), '[null,1,"2",false,true]')
    t:are_equal(json_pure_encode({1, "2", {a = 1}}), '[1,"2",{"a":1}]')
    t:are_equal(json_pure_encode({1, "2", {b = true}}), '[1,"2",{"b":true}]')
    t:are_equal(json_pure_encode(json.mark_as_array({1, 0xa, 0xdeadbeef, 0xffffffff, -1})), '[1,10,3735928559,4294967295,-1]')
    local pretty_expected = table.concat({
        "{",
        "    \"name\": \"xmake\",",
        "    \"targets\": [",
        "        \"foo\",",
        "        \"bar\"",
        "    ]",
        "}"
    }, "\n")
    t:are_equal(json.encode({name = "xmake", targets = {"foo", "bar"}}, {pure = true, pretty = true, indent = 4}), pretty_expected)
end
