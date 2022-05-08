import("core.compress.lz4")

function test_lz4(t)
    t:are_equal(lz4.decompress(lz4.compress("hello world")):str(), "hello world")
    t:are_equal(lz4.block_decompress(lz4.block_compress("hello world"), 11):str(), "hello world")
end

