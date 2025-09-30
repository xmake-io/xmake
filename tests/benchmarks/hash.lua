import("core.base.bytes")

local COUNT = 1000000

function test_md5(data)
    data = bytes(data)
    local h
    local n = COUNT / 10000
    local t = os.mclock()
    for i = 1, n do
        h = hash.md5(data)
    end
    t = os.mclock() - t
    print("md5(%d): %d ms, hash: %s", COUNT, t * 10000, h)
end

function test_sha1(data)
    data = bytes(data)
    local h
    local n = COUNT / 10000
    local t = os.mclock()
    for i = 1, n do
        h = hash.sha1(data)
    end
    t = os.mclock() - t
    print("sha1(%d): %d ms, hash: %s", COUNT, t * 10000, h)
end

function test_sha256(data)
    data = bytes(data)
    local h
    local n = COUNT / 10000
    local t = os.mclock()
    for i = 1, n do
        h = hash.sha256(data)
    end
    t = os.mclock() - t
    print("sha256(%d): %d ms, hash: %s", COUNT, t * 10000, h)
end

function test_uuid(data)
    local h
    local n = COUNT / 10000
    local t = os.mclock()
    for i = 1, n do
        h = hash.uuid(data)
    end
    t = os.mclock() - t
    print("uuid(%d): %d ms, hash: %s", COUNT, t * 10000, h)
end

function test_xxhash32(data)
    data = bytes(data)
    local h
    local n = COUNT / 10
    local t = os.mclock()
    for i = 1, n do
        h = hash.xxhash32(data)
    end
    t = os.mclock() - t
    print("xxhash32(%d): %d ms, hash: %s", COUNT, t * 10, h)
end

function test_xxhash64(data)
    data = bytes(data)
    local h
    local n = COUNT / 10
    local t = os.mclock()
    for i = 1, n do
        h = hash.xxhash64(data)
    end
    t = os.mclock() - t
    print("xxhash64(%d): %d ms, hash: %s", COUNT, t * 10, h)
end

function test_xxhash128(data)
    data = bytes(data)
    local h
    local n = COUNT / 10
    local t = os.mclock()
    for i = 1, n do
        h = hash.xxhash128(data)
    end
    t = os.mclock() - t
    print("xxhash128(%d): %d ms, hash: %s", COUNT, t * 10, h)
end

function test_strhash32(data)
    local h
    local n = COUNT / 10
    local t = os.mclock()
    for i = 1, n do
        h = hash.strhash32(data)
    end
    t = os.mclock() - t
    print("strhash32(%d): %d ms, hash: %s", COUNT, t * 10, h)
end

function test_strhash64(data)
    local h
    local n = COUNT / 10
    local t = os.mclock()
    for i = 1, n do
        h = hash.strhash64(data)
    end
    t = os.mclock() - t
    print("strhash64(%d): %d ms, hash: %s", COUNT, t * 10, h)
end

function test_strhash128(data)
    local h
    local n = COUNT / 10
    local t = os.mclock()
    for i = 1, n do
        h = hash.strhash128(data)
    end
    t = os.mclock() - t
    print("strhash128(%d): %d ms, hash: %s", COUNT, t * 10, h)
end

function test_random_uuid()
    local h
    local n = COUNT / 1000
    local t = os.mclock()
    for i = 1, n do
        h = hash.uuid()
    end
    t = os.mclock() - t
    print("uuid(%d): %d ms, hash: %s", COUNT, t * 1000, h)
end

function test_random32()
    local h
    local n = COUNT / 10
    local t = os.mclock()
    for i = 1, n do
        h = hash.random32()
    end
    t = os.mclock() - t
    print("random32(%d): %d ms, hash: %s", COUNT, t * 10, h)
end

function test_random64()
    local h
    local n = COUNT / 10
    local t = os.mclock()
    for i = 1, n do
        h = hash.random64()
    end
    t = os.mclock() - t
    print("random64(%d): %d ms, hash: %s", COUNT, t * 10, h)
end

function test_random128()
    local h
    local n = COUNT / 10
    local t = os.mclock()
    for i = 1, n do
        h = hash.random128()
    end
    t = os.mclock() - t
    print("random128(%d): %d ms, hash: %s", COUNT, t * 10, h)
end

function test_longstr()
    print("========================================== test long string ==========================================")
    local data = ""
    for i = 1, 10000 do
        data = data .. "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    end
    test_md5(data)
    test_sha1(data)
    test_sha256(data)
    test_uuid(data)
    test_xxhash32(data)
    test_xxhash64(data)
    test_xxhash128(data)
    test_strhash32(data)
    test_strhash64(data)
    test_strhash128(data)
end

function test_shortstr()
    print("========================================== test short string ==========================================")
    COUNT = COUNT * 100
    local data = ""
    for i = 1, 10 do
        data = data .. "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    end
    test_md5(data)
    test_sha1(data)
    test_sha256(data)
    test_uuid(data)
    test_xxhash32(data)
    test_xxhash64(data)
    test_xxhash128(data)
    test_strhash32(data)
    test_strhash64(data)
    test_strhash128(data)
end

function test_random()
    print("========================================== test random ==========================================")
    test_random_uuid()
    test_random32()
    test_random64()
    test_random128()
end

function main()
    test_longstr()
    test_shortstr()
    test_random()
end
