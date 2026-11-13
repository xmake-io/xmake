import("lib.detect.find_tool")

function _with_temp_project(callback)
    local clang_format = find_tool("clang-format")
    if not clang_format then
        return nil, "clang-format not found"
    end

    local tempdir = os.tmpfile()
    os.mkdir(tempdir)
    local olddir = os.cd(tempdir)
    try
    {
        function ()
            io.writefile(".clang-format", "BasedOnStyle: LLVM\n")
            callback(tempdir)
        end,
        finally
        {
            function ()
                os.cd(olddir)
                os.tryrm(tempdir)
            end
        }
    }
    return true
end

function test_format_targets_and_rules(t)
    local ok, reason = _with_temp_project(function ()
        os.mkdir("src")
        os.mkdir("include")
        os.mkdir("build/.gens/app/sub")
        os.mkdir("build/.gens/app_other")

        io.writefile("xmake.lua", [[
add_rules("mode.debug", "mode.release")

target("app")
    set_kind("binary")
    add_rules("qt.moc", "qt.qmltyperegistrar", "qt.ui")
    add_files("src/main.cpp", "src/widget.h", "src/qml.hpp", "src/widget.ui", "src/mod.cppm")
    add_files("build/.gens/app/sub/gen.cpp", {always_added = true})
    add_files("build/.gens/app_other/other.cpp", {always_added = true})
    add_files("src/uncreated.cpp", {always_added = true})
    add_headerfiles("$(projectdir)/include/*.h")

target("lib")
    set_kind("static")
    add_files("./src/main.cpp")
    add_headerfiles("include/*.h", "src/widget.h")
]])

        local raw_main = "int   main(){return 0;}\n"
        local raw_widget = "class   Widget{};\n"
        local raw_qml = "class   QmlType{};\n"
        local raw_mod = "export module mod;\nint   mod_fn(){return 1;}\n"
        local raw_header = "int   foo();\n"
        local raw_other = "int   other(){return 2;}\n"
        local raw_gen = "int   gen(){return 3;}\n"
        local raw_ui = "<ui version=\"4.0\"><widget class=\"QWidget\"/></ui>\n"

        io.writefile("src/main.cpp", raw_main)
        io.writefile("src/widget.h", raw_widget)
        io.writefile("src/qml.hpp", raw_qml)
        io.writefile("src/mod.cppm", raw_mod)
        io.writefile("include/foo.h", raw_header)
        io.writefile("build/.gens/app_other/other.cpp", raw_other)
        io.writefile("build/.gens/app/sub/gen.cpp", raw_gen)
        io.writefile("src/widget.ui", raw_ui)

        local outdata, errdata = os.iorunv("xmake", {"format", "-n", "-v"})
        local output = outdata .. (errdata or "")
        t:require(outdata:find("formatted 6 files", 1, true))
        t:require(not output:find("widget.ui", 1, true))
        t:require(not output:find("gen.cpp", 1, true))

        os.vrunv("xmake", {"format"})

        t:require(io.readfile("src/main.cpp") ~= raw_main)
        t:require(io.readfile("src/widget.h") ~= raw_widget)
        t:require(io.readfile("src/qml.hpp") ~= raw_qml)
        t:require(io.readfile("src/mod.cppm") ~= raw_mod)
        t:require(io.readfile("include/foo.h") ~= raw_header)
        t:require(io.readfile("build/.gens/app_other/other.cpp") ~= raw_other)

        -- generated files inside target:autogendir() and non-C++ rule files must remain untouched
        t:are_equal(io.readfile("build/.gens/app/sub/gen.cpp"), raw_gen)
        t:are_equal(io.readfile("src/widget.ui"), raw_ui)
    end)
    if not ok then
        return t:skip(reason)
    end
end

function test_format_files_option(t)
    local ok, reason = _with_temp_project(function ()
        os.mkdir("src")
        os.mkdir("include")
        os.mkdir("build/.gens/app")

        io.writefile("xmake.lua", [[
add_rules("mode.debug", "mode.release")

target("app")
    set_kind("binary")
    add_rules("qt.moc", "qt.ui")
    add_files("src/main.cpp", "src/widget.h", "src/widget.ui")
    add_files("build/.gens/app/gen.cpp", {always_added = true})
    add_headerfiles("$(projectdir)/include/abs.h", "$(projectdir)/include/foo.h")

target("lib")
    set_kind("static")
    add_files("src/main.cpp")
    add_headerfiles("include/foo.h")
]])

        local raw_main = "int   main(){return 0;}\n"
        local raw_widget = "class   Widget{};\n"
        local raw_foo = "int   foo();\n"
        local raw_abs = "int   abs_fn();\n"
        local raw_gen = "int   gen(){return 1;}\n"
        local raw_ui = "<ui version=\"4.0\"></ui>\n"

        io.writefile("src/main.cpp", raw_main)
        io.writefile("src/widget.h", raw_widget)
        io.writefile("include/foo.h", raw_foo)
        io.writefile("include/abs.h", raw_abs)
        io.writefile("build/.gens/app/gen.cpp", raw_gen)
        io.writefile("src/widget.ui", raw_ui)

        -- exclude pattern must stay excluded and not bypass via abs_file fallback
        local excluded_out, excluded_err = os.iorunv("xmake", {"format", "-n", "-v", "-f", "src/**|src/widget.h"})
        local excluded_output = excluded_out .. (excluded_err or "")
        t:require(excluded_out:find("formatted 1 files", 1, true))
        t:require(not excluded_output:find("widget.h", 1, true))
        t:require(not excluded_output:find("widget.ui", 1, true))

        -- absolute headerfiles() paths still match relative --files patterns and ignore non-C++ batches
        local rel_out = os.iorunv("xmake", {"format", "-n", "-v", "-f", "include/*.h"})
        t:require(rel_out:find("formatted 2 files", 1, true))

        -- absolute --files patterns also match
        local abs_pattern = path.join(os.curdir(), "include", "abs.h")
        local abs_out = os.iorunv("xmake", {"format", "-n", "-v", "-f", abs_pattern})
        t:require(abs_out:find("formatted 1 files", 1, true))

        -- format only src/** and ensure qt.ui and headers outside src/ stay untouched
        os.vrunv("xmake", {"format", "-f", "src/**"})
        t:require(io.readfile("src/main.cpp") ~= raw_main)
        t:require(io.readfile("src/widget.h") ~= raw_widget)
        t:are_equal(io.readfile("src/widget.ui"), raw_ui)
        t:are_equal(io.readfile("include/foo.h"), raw_foo)
        t:are_equal(io.readfile("include/abs.h"), raw_abs)
        t:are_equal(io.readfile("build/.gens/app/gen.cpp"), raw_gen)

        -- format only relative include/*.h pattern
        os.vrunv("xmake", {"format", "-f", "include/*.h"})
        t:require(io.readfile("include/foo.h") ~= raw_foo)
        t:require(io.readfile("include/abs.h") ~= raw_abs)
    end)
    if not ok then
        return t:skip(reason)
    end
end
