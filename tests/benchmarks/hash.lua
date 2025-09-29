local COUNT = 1000000

function test_md5(data)
    local h
    local t = os.mclock()
    for i = 1, COUNT do
        h = hash.md5(data)
    end
    t = os.mclock() - t
    print("md5(%d): %d ms, hash: %s", COUNT, t, h)
end

function test_sha1(data)
    local h
    local t = os.mclock()
    for i = 1, COUNT do
        h = hash.sha1(data)
    end
    t = os.mclock() - t
    print("sha1(%d): %d ms, hash: %s", COUNT, t, h)
end

function test_sha256(data)
    local h
    local t = os.mclock()
    for i = 1, COUNT do
        h = hash.sha256(data)
    end
    t = os.mclock() - t
    print("sha256(%d): %d ms, hash: %s", COUNT, t, h)
end

function test_uuid(data)
    local h
    local t = os.mclock()
    for i = 1, COUNT do
        h = hash.uuid(data)
    end
    t = os.mclock() - t
    print("uuid(%d): %d ms, hash: %s", COUNT, t, h)
end

function test_uuid4(data)
    local h
    local t = os.mclock()
    for i = 1, COUNT do
        h = hash.uuid4(data)
    end
    t = os.mclock() - t
    print("uuid4(%d): %d ms, hash: %s", COUNT, t, h)
end

function test_strhash32(data)
    local h
    local t = os.mclock()
    for i = 1, COUNT do
        h = hash.strhash32(data)
    end
    t = os.mclock() - t
    print("strhash32(%d): %d ms, hash: %s", COUNT, t, h)
end

function test_strhash128(data)
    local h
    local t = os.mclock()
    for i = 1, COUNT do
        h = hash.strhash128(data)
    end
    t = os.mclock() - t
    print("strhash128(%d): %d ms, hash: %s", COUNT, t, h)
end

function main()
    local data = io.readfile(os.programfile())
    --test_md5(data)
    --test_sha1(data)
    --test_sha256(data)
    test_uuid(data)
    test_uuid4(data)
    test_strhash32(data)
    test_strhash128(data)
end
