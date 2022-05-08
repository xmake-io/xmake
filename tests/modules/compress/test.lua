import("core.compress.lz4")

function test_lz4_frame_compress(t)
    t:are_equal(lz4.decompress(lz4.compress("hello world")):str(), "hello world")
end

