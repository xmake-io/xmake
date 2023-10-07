add_rules("mode.debug", "mode.release")

for _, file in ipairs(os.files("src/test_*.cpp")) do
    local name = path.basename(file)
    target(name)
        set_kind("binary")
        set_default(false)
        add_files("src/" .. name .. ".cpp")
        add_tests(name)
        add_tests(name .. "_args", {arguments = {"foo", "bar"}})
        add_tests(name .. "_pass_output", {arguments = "foo", pass_output = "hello foo"})
        add_tests(name .. "_fail_output", {fail_output = {"hello .*", "hello xmake"}})
end

