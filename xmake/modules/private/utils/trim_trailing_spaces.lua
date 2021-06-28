function main(pattern)
    for _, filepath in ipairs(os.files(pattern)) do
        local filedata = io.readfile(filepath)
        if filedata then
            local filedata2 = {}
            for _, line in ipairs(filedata:split('\n', {strict = true})) do
                line = line:rtrim()
                table.insert(filedata2, line)
            end
            io.writefile(filepath, table.concat(filedata2, "\n"))
        end
    end
end
