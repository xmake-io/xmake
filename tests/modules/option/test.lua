import("core.base.option")

local function _options()
    return {
        {"v", "verbose", "k"},
        {"o", "output", "kv", "default.txt"},
        {nil, "enabled", "kv", true},
        {nil, "input", "v"}
    }
end

function test_raw_parse_string(t)
    t:are_equal(option.raw_parse('-v -o "output file.txt" --enabled=no "input file.bin"', _options()),
        {verbose = true, output = "output file.txt", enabled = false, input = "input file.bin"})
    t:are_equal(option.raw_parse('--output=custom -- -literal', _options()),
        {output = "custom", enabled = true, input = "-literal"})
end

function test_parse_string(t)
    local result = option.parse('--output="output file.txt" -v "input file.bin"', _options())
    t:are_equal(result.output, "output file.txt")
    t:are_equal(result.verbose, true)
    t:are_equal(result.input, "input file.bin")
    t:are_equal(result.enabled, true)
    t:are_equal(type(result.help), "function")
end

function test_parse_controls(t)
    t:are_equal(option.raw_parse({"-v", "-o", "output file.txt", "--enabled=no", "input file.bin"}, _options()),
        {verbose = true, output = "output file.txt", enabled = false, input = "input file.bin"})
    t:are_equal(option.raw_parse({}, _options()), {output = "default.txt", enabled = true})
    t:are_equal(option.raw_parse("", _options()), {output = "default.txt", enabled = true})
    t:are_equal(option.raw_parse({"-o", "custom"}, _options(), {populate_defaults = false}), {output = "custom"})
end
