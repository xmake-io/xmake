function _with_temp_project(callback)
    local tempdir = os.tmpfile()
    os.mkdir(tempdir)
    local olddir = os.cd(tempdir)
    try
    {
        function ()
            callback(tempdir)
        end,
        finally
        {
            function (ok, errors)
                os.cd(olddir)
                os.tryrm(tempdir)
                if not ok then
                    raise(errors)
                end
            end
        }
    }
end

function test_basic(t)
    os.exec("xmake test")
end

function test_default_all_and_policy(t)
    _with_temp_project(function ()
        os.mkdir("src")
        io.writefile("xmake.lua", [[
add_rules("mode.debug", "mode.release")

target("unit_fast")
    set_kind("binary")
    set_default(false)
    add_files("src/main.cpp")
    add_defines('TAG="unit_fast"')
    add_tests("default")
    add_tests("heavy_case", {default = false, group = "bench", runargs = "heavy"})

target("unit_default_target")
    set_kind("binary")
    add_files("src/main.cpp")
    add_defines('TAG="unit_default_target"')
    add_tests("fast", {runargs = "fast"})
    add_tests("slow", {default = false, runargs = "slow"})

target("bench_only")
    set_kind("binary")
    set_default(false)
    add_files("src/main.cpp")
    add_defines('TAG="bench_only"')
    add_tests("default", {default = false, group = "bench"})

target("bench_policy")
    set_kind("binary")
    set_default(false)
    set_group("bench")
    set_policy("test.respect_default", true)
    add_files("src/main.cpp")
    add_defines('TAG="bench_policy"')
    add_tests("default")
    add_tests("forced", {default = true, runargs = "forced"})
]])
        io.writefile("src/main.cpp", [[
#include <iostream>
int main(int argc, char** argv) {
    std::cout << "RUN:" << TAG << ":" << (argc > 1 ? argv[1] : "none") << std::endl;
    return 0;
}
]])

        -- default run: skips non-default tests and skips building bench_only
        local out = os.iorunv("xmake", {"test", "-v"})
        t:require(out:find("RUN:unit_fast:none", 1, true))
        t:require(out:find("RUN:unit_default_target:fast", 1, true))
        t:require(out:find("RUN:bench_policy:forced", 1, true))
        t:require(not out:find("RUN:unit_fast:heavy", 1, true))
        t:require(not out:find("RUN:unit_default_target:slow", 1, true))
        t:require(not out:find("RUN:bench_only:none", 1, true))
        t:require(not out:find("RUN:bench_policy:none", 1, true))
        t:require(not out:find("bench_only", 1, true))

        -- -a / --all runs everything including non-default tests
        local out_all = os.iorunv("xmake", {"test", "--all", "-v"})
        t:require(out_all:find("RUN:unit_fast:none", 1, true))
        t:require(out_all:find("RUN:unit_fast:heavy", 1, true))
        t:require(out_all:find("RUN:unit_default_target:fast", 1, true))
        t:require(out_all:find("RUN:unit_default_target:slow", 1, true))
        t:require(out_all:find("RUN:bench_only:none", 1, true))
        t:require(out_all:find("RUN:bench_policy:none", 1, true))
        t:require(out_all:find("RUN:bench_policy:forced", 1, true))

        -- -g bench runs bench group even when default = false
        local out_group = os.iorunv("xmake", {"test", "-g", "bench", "-v"})
        t:require(out_group:find("RUN:unit_fast:heavy", 1, true))
        t:require(out_group:find("RUN:bench_only:none", 1, true))
        t:require(out_group:find("RUN:bench_policy:none", 1, true))
        t:require(not out_group:find("RUN:unit_default_target:fast", 1, true))

        -- explicit test pattern runs matched non-default test
        local out_explicit = os.iorunv("xmake", {"test", "-v", "bench_only/default"})
        t:require(out_explicit:find("RUN:bench_only:none", 1, true))
        t:require(not out_explicit:find("RUN:unit_default_target:fast", 1, true))
    end)

    -- root-level test.respect_default policy with target-level override and empty default run
    _with_temp_project(function ()
        os.mkdir("src")
        io.writefile("xmake.lua", [[
add_rules("mode.debug", "mode.release")
set_policy("test.respect_default", true)

target("root_skipped")
    set_kind("binary")
    set_default(false)
    add_files("src/main.cpp")
    add_defines('TAG="root_skipped"')
    add_tests("default")
]])
        io.writefile("src/main.cpp", [[
#include <iostream>
int main() {
    std::cout << "RUN:" << TAG << std::endl;
    return 0;
}
]])

        local out_empty = os.iorunv("xmake", {"test", "-v"})
        t:require(out_empty:find("nothing to test", 1, true))
        t:require(not out_empty:find("RUN:root_skipped", 1, true))

        local out_all = os.iorunv("xmake", {"test", "-a", "-v"})
        t:require(out_all:find("RUN:root_skipped", 1, true))

        -- target-level override disables root policy while keeping explicit test default = false
        io.writefile("xmake.lua", [[
add_rules("mode.debug", "mode.release")
set_policy("test.respect_default", true)

target("root_skipped")
    set_kind("binary")
    set_default(false)
    add_files("src/main.cpp")
    add_defines('TAG="root_skipped"')
    add_tests("default")

target("target_override")
    set_kind("binary")
    set_default(false)
    set_policy("test.respect_default", false)
    add_files("src/main.cpp")
    add_defines('TAG="target_override"')
    add_tests("default")
    add_tests("explicit_off", {default = false})
]])
        local out_override = os.iorunv("xmake", {"test", "-v"})
        t:require(not out_override:find("RUN:root_skipped", 1, true))
        t:require(out_override:find("RUN:target_override", 1, true))
        t:require(not out_override:find("explicit_off", 1, true))
    end)
end

