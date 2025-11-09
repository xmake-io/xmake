local function _prepare_source(dir)
    os.mkdir(dir)
    io.writefile(path.join(dir, "foo.txt"), "foo")
    io.writefile(path.join(dir, "bar.txt"), "bar")
end

function main()
    local root = os.tmpfile() .. ".os_async_copy"
    local srcdir = path.join(root, "src")
    local dstdir = path.join(root, "dst")

    _prepare_source(srcdir)
    print("source prepared: %s", srcdir)

    local files = os.files(path.join(srcdir, "*.txt"), {async = true})
    assert(files and #files == 2)
    print("async enumerate: %d files", #files)

    os.cp(srcdir, dstdir, {async = true})
    assert(os.isdir(dstdir))
    print("async copy done: %s", dstdir)

    files = os.files(path.join(dstdir, "*.txt"), {async = true})
    assert(files and #files == 2)

    os.rm(dstdir, {async = true})
    assert(not os.isdir(dstdir))
    print("dst removed async")

    os.rm(srcdir, {async = true})
    os.tryrm(root)
    print("async copy test finished")
end

