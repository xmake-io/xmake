-- This local repository is part of the example; no manual addon installation is needed.
add_repositories("example-includes-repo ./repo", {rootdir = os.scriptdir()})
add_addons("example-includes")
includes("@addon/example-includes/options")

add_rules("mode.debug", "mode.release")

target("hello")
    set_kind("binary")
    add_files("src/main.c")
    on_config(function (target)
        if has_config("example_verbose") then
            target:add("defines", "EXAMPLE_VERBOSE")
        end
    end)
