add_rules("mode.debug", "mode.release")
set_policy("test.return_zero_on_failure", true)

for _, file in ipairs(os.files("src/test_*.cpp")) do
    local name = path.basename(file)
    target(name)
        set_kind("binary")
        set_default(false)
        add_files("src/" .. name .. ".cpp")
        add_tests("default")
        add_tests("args", {runargs = {"foo", "bar"}})
        add_tests("pass_output", {trim_output = true, runargs = "foo", pass_outputs = "hello foo"})
        add_tests("fail_output", {fail_outputs = {"hello2 .*", "hello xmake"}})
end

target("test_compile")
    set_kind("binary")
    set_default(false)
    add_files("src/compile.cpp")
    add_tests("compile", {build_only = true})
