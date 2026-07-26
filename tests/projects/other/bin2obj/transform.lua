function main(inputfile, outputfile)
    import("core.base.bytes")
    local data = io.readfile(inputfile, {encoding = "binary"})
    io.writefile(outputfile, data:reverse(), {encoding = "binary"})
end
