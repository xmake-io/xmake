import("core.base.bytes")

function test_ctor(t)
    t:are_equal(bytes("123456789"):str(), "123456789")
    t:are_equal(bytes(bytes("123456789")):str(), "123456789")
    t:are_equal(bytes(bytes("123456789"), 3, 5):str(), "345")
    t:are_equal(bytes("123456789"):size(), 9)
    t:are_equal(bytes(10):size(), 10)
    t:are_equal(bytes(bytes("123"), bytes("456"), bytes("789")):str(), "123456789")
    t:are_equal(bytes({bytes("123"), bytes("456"), bytes("789")}):str(), "123456789")
end

function test_clone(t)
    t:are_equal(bytes(10):clone():size(), 10)
    t:are_equal(bytes("123456789"):clone():str(), "123456789")
end

function test_slice(t)
    t:are_equal(bytes(10):slice(1, 2):size(), 2)
    t:are_equal(bytes("123456789"):slice(1, 4):str(), "1234")
end

function test_index(t)
    local b = bytes("123456789")
    t:are_equal(b[{1, 4}]:str(), "1234")
    t:will_raise(function() b[1] = string.byte('2') end)
    b = bytes(9)
    b[{1, 9}] = bytes("123456789")
    t:are_equal(b:str(), "123456789")
    b[1] = string.byte('2')
    t:are_equal(b:str(), "223456789")
    t:will_raise(function() b[100] = string.byte('2') end)
end

function test_concat(t)
    t:are_equal((bytes("123") .. bytes("456")):str(), "123456")
    t:are_equal(bytes(bytes("123"), bytes("456")):str(), "123456")
end
