
function test_async(t)
    local tmpdir = os.tmpfile() .. ".dir"
    local tmpdir2 = os.tmpfile() .. ".dir"
    io.writefile(path.join(tmpdir, "foo.txt"), "foo")
    io.writefile(path.join(tmpdir, "bar.txt"), "bar")
    print("1111")
    local files = os.files(path.join(tmpdir, "*.txt"), {async = true})
    t:require(files and #files == 2)

    print("1111")
    os.cp(tmpdir, tmpdir2, {async = true, detach = true})
    t:require(not os.isdir(tmpdir2))

    print("1111")
    os.cp(tmpdir, tmpdir2, {async = true})
    t:require(os.isdir(tmpdir2))

    print("1111")
    t:require(os.isdir(tmpdir))
    os.rm(tmpdir, {async = true})
    t:require(not os.isdir(tmpdir))

    print("1111")
    t:require(os.isdir(tmpdir2))
    os.rm(tmpdir2, {async = true, detach = true})
    t:require(os.isdir(tmpdir2))

    print("1111")
end
