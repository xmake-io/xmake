function main(t)
    t:build()
    -- run the target, main.c verifies the transformed asset.bin and exits non-zero on mismatch
    os.exec("xmake run test")
end
