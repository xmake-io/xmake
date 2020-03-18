
function _lastof_perf(str, pattern, opt)
    local plain = opt and opt.plain
    local dt = os.mclock()
    for i = 0, 1000000 do
        str:lastof(pattern, plain)
    end
    dt = os.mclock() - dt
    print("lastof(%s .., %s, %s): %d ms", str:sub(1, 16), pattern, string.serialize(opt or {}, {strip = true, indent = false}), dt)
end

function main()

    local str = "shortstr: 123abc123123xyz[123]+abc123"
    _lastof_perf(str, "1")
    _lastof_perf(str, "123")
    _lastof_perf(str, "[123]+")
    print("")

    _lastof_perf(str, "1", {plain = true})
    _lastof_perf(str, "123", {plain = true})
    _lastof_perf(str, "[123]+", {plain = true})
    print("")

    str = "longstr: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    for i = 0, 100 do
        str = str .. "[123]+"
    end
    _lastof_perf(str, "1")
    _lastof_perf(str, "123")
    _lastof_perf(str, "[123]+")
    print("")

    _lastof_perf(str, "1", {plain = true})
    _lastof_perf(str, "123", {plain = true})
    _lastof_perf(str, "[123]+", {plain = true})
    print("")
end
