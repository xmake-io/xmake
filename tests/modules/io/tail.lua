function main(filepath, linecount, continuation, encoding)
    io.tail(filepath, tonumber(linecount), {
        continuation = continuation ~= "" and continuation or nil,
        encoding = encoding ~= "" and encoding or nil
    })
end
