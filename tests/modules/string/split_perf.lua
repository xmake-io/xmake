
function _split_perf(str, delimiter, opt)
    local dt = os.mclock()
    for i = 0, 1000000 do
        str:split(delimiter, opt)
    end
    dt = os.mclock() - dt
    print("split(%s .., %s, %s): %d ms", str:sub(1, 16), delimiter, string.serialize(opt or {}, {strip = true, indent = false}), dt)
end

function main()

    local str = "shortstr: 123abc123123xyz[123]+abc123"
    _split_perf(str, "1")
    _split_perf(str, "123")
    _split_perf(str, "[123]+")
    print("")

    _split_perf(str, "1", {plain = true})
    _split_perf(str, "123", {plain = true})
    _split_perf(str, "[123]+", {plain = true})
    print("")

    str = "longstr: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    for i = 0, 100 do
        str = str .. "[123]+"
    end
    _split_perf(str, "1")
    _split_perf(str, "123")
    _split_perf(str, "[123]+")
    print("")

    _split_perf(str, "1", {plain = true})
    _split_perf(str, "123", {plain = true})
    _split_perf(str, "[123]+", {plain = true})
    print("")
end
