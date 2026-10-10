import("core.base.bytes")

local function _empty_sources()
    return {
        {"string", ""},
        {"string_bytes", bytes("")},
        {"constructor", bytes()},
        {"table_constructor", bytes({})}
    }
end

function test_copy_empty_source(t)
    for _, source in ipairs(_empty_sources()) do
        local dst = bytes(3):copy("abc")
        t:are_equal(dst:copy(source[2]) == dst, true)
        t:are_equal(dst:str(), "abc")
        print("BOUNDARY_PASS copy_" .. source[1])
    end
end

function test_copy2_empty_source(t)
    for _, source in ipairs(_empty_sources()) do
        for _, pos in ipairs({1, 3}) do
            local dst = bytes(3):copy("abc")
            t:are_equal(dst:copy2(pos, source[2]) == dst, true)
            t:are_equal(dst:str(), "abc")
            print("BOUNDARY_PASS copy2_" .. source[1] .. "_pos" .. pos)
        end
    end
end

function test_slice_endpoints(t)
    local src = bytes("abc")
    local origin = debug.getinfo(src.slice).source
    t:are_equal(path.translate(path.absolute(origin:sub(2), os.workingdir())),
                path.translate(path.join(os.programdir(), "core/base/bytes.lua")))
    print("BOUNDARY_SOURCE=" .. origin)
    t:are_equal(src:slice(1, 1):str(), "a")
    t:are_equal(src:slice(3, 3):str(), "c")
    t:are_equal(src:slice(1, 3):str(), "abc")
    t:are_equal(src[{3, 3}]:str(), "c")
end

function test_copy_endpoints(t)
    t:are_equal(bytes(3):copy("abc"):str(), "abc")
    t:are_equal(bytes(1):copy("abc", 3, 3):str(), "c")
    t:are_equal(bytes(3):copy("abc"):copy2(3, "xyz", 3, 3):str(), "abz")
end

function test_readonly_empty_copy(t)
    t:will_raise(function() bytes("abc"):copy("") end)
    t:will_raise(function() bytes("abc"):copy2(1, bytes()) end)
end
