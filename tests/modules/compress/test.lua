import("core.compress.lz4")

function test_lz4(t)
    t:are_equal(lz4.decompress(lz4.compress("hello world")):str(), "hello world")
    t:are_equal(lz4.block_decompress(lz4.block_compress("hello world"), 11):str(), "hello world")
    local srcfile = os.tmpfile() .. ".src"
    local dstfile = os.tmpfile() .. ".dst"
    local dstfile2 = os.tmpfile() .. ".dst2"
    io.writefile(srcfile, "hello world")
    lz4.compress_file(srcfile, dstfile)
    lz4.decompress_file(dstfile, dstfile2)
    t:are_equal(io.readfile(srcfile), io.readfile(dstfile2))
end

