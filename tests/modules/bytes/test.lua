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

function test_copy(t)
    t:are_equal(bytes(9):copy("123456789"):str(), "123456789")
    t:are_equal(bytes(5):copy("123456789", 5, 9):str(), "56789")
end

function test_copy2(t)
    t:are_equal(bytes(18):copy("123456789"):copy2(10, "123456789"):str(), "123456789123456789")
    t:are_equal(bytes(14):copy("123456789"):copy2(10, "123456789", 5, 9):str(), "12345678956789")
end

function test_move(t)
    t:are_equal(bytes(9):copy("123456789"):move(5, 9):str(), "567896789")
    t:are_equal(bytes(9):copy("123456789"):move2(2, 5, 9):str(), "156789789")
end

function test_int(t)
    t:are_equal(bytes(1):u8_set(1, 1):u8(1), 1)
    t:are_equal(bytes(10):u8_set(5, 255):u8(5), 255)
    t:are_equal(bytes(10):u16le_set(5, 12346):u16le(5), 12346)
    t:are_equal(bytes(10):u16be_set(5, 12346):u16be(5), 12346)
    t:are_equal(bytes(20):u32le_set(5, 12345678):u32le(5), 12345678)
    t:are_equal(bytes(20):u32be_set(5, 12345678):u32be(5), 12345678)
end


function test_signed32(t)
    local cases = {
        {"\0\0\0\0", "\0\0\0\0", 0},
        {"\1\0\0\0", "\0\0\0\1", 1},
        {"\xff\xff\xff\x7f", "\x7f\xff\xff\xff", 2147483647},
        {"\0\0\0\x80", "\x80\0\0\0", -2147483648},
        {"\xfe\xff\xff\xff", "\xff\xff\xff\xfe", -2},
        {"\xff\xff\xff\xff", "\xff\xff\xff\xff", -1}
    }
    for _, case in ipairs(cases) do
        t:are_equal(bytes(case[1]):s32le(1), case[3])
        t:are_equal(bytes(case[2]):s32be(1), case[3])
        t:are_equal(bytes("x" .. case[1] .. "y"):s32le(2), case[3])
        t:are_equal(bytes("x" .. case[2] .. "y"):s32be(2), case[3])
    end
    t:are_equal(bytes("\xff"):s8(1), -1)
    t:are_equal(bytes("\xff\xff"):s16le(1), -1)
    t:are_equal(bytes("\xff\xff"):s16be(1), -1)
end
