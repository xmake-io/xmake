includes("@builtin/check")

add_rules("mode.release", "mode.debug")

option("version", {description = "The ninja version."})
set_version("$(version)")

set_languages("c++14")
check_cfuncs("USE_PPOLL=1", "ppoll", {includes = "poll.h"})

target("libninja")
    set_kind("$(kind)")
    set_basename("ninja")

	add_files("src/build_log.cc")
	add_files("src/build.cc")
	add_files("src/clean.cc")
	add_files("src/clparser.cc")
	add_files("src/debug_flags.cc")
	add_files("src/deps_log.cc")
	add_files("src/disk_interface.cc")
	add_files("src/edit_distance.cc")
	add_files("src/eval_env.cc")
	add_files("src/graph.cc")
	add_files("src/graphviz.cc")
	add_files("src/line_printer.cc")
	add_files("src/manifest_parser.cc")
	add_files("src/metrics.cc")
	add_files("src/state.cc")
	add_files("src/string_piece_util.cc")
	add_files("src/util.cc")
	add_files("src/version.cc")
    add_files("src/depfile_parser.cc", "src/lexer.cc")

    if is_plat("windows", "mingw", "msys") then
		add_files("src/subprocess-win32.cc")
		add_files("src/includes_normalize-win32.cc")
		add_files("src/msvc_helper-win32.cc")
		add_files("src/msvc_helper_main-win32.cc")
		add_files("src/getopt.c", {sourcekind = "cxx"})
		add_files("src/minidump-win32.cc")

        add_defines("NOMINMAX")
    else
		add_files("src/subprocess-posix.cc")
    end

    if is_plat("mingw") then
        add_defines("_WIN32_WINNT=0x0601", "__USE_MINGW_ANSI_STDIO=1")
    end

    on_load(function (target)
        import("core.base.semver")
        local version = semver.new(target:version())
        if version:ge("1.13.1") then
            target:add("files", "src/elide_middle.cc")
            target:add("files", "src/jobserver.cc")
            target:add("files", "src/real_command_runner.cc")
            target:add("files", "src/status_printer.cc")
            if target:is_plat("windows", "mingw", "msys2") then
		        target:add("files", "src/jobserver-win32.cc")
            else
                target:add("files", "src/jobserver-posix.cc")
            end
        end
        if version:ge("1.11.0") then
            if version:lt("1.13.1") then
                target:add("files", "src/status.cc")
            end
	        target:add("files", "src/json.cc")
	        target:add("files", "src/missing_deps.cc")
        end
        if version:ge("1.10.0") then
            target:add("files", "src/dyndep.cc")
            target:add("files", "src/dyndep_parser.cc")
            target:add("files", "src/parser.cc")
        end
    end)

target("ninja")
    set_kind("binary")
    add_deps("libninja")

    add_files("src/ninja.cc")
    if is_plat("windows") then
        add_files("windows/ninja.manifest")
    end
