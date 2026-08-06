add_rules("mode.debug", "mode.release")
set_languages("c++latest")

-- test that a plain c++ file is ordered after all the bmis it reuses from its deps,
-- not only after the last one
--
-- @note foo must not import std, otherwise its bmi and the std bmi
-- would not be built by two distinct jobs of the foo target
--
-- @see https://github.com/xmake-io/xmake/issues/7690
target("foo")
    set_kind("static")
    add_files("src/foo.cpp")
    add_files("src/foo.mpp", {public = true})

target("main")
    set_kind("binary")
    add_deps("foo")
    add_files("src/main.cpp")
