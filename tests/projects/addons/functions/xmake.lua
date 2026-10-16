add_repositories("example-functions-repo ./repo", {rootdir = os.scriptdir()})
add_addons("example-functions")
includes("@addon/example-functions/targets")

-- Skip addon APIs during the first scan, before automatic installation.
if example_console then
    example_console("hello", "src/main.c")

    target("hello")
        add_defines("EXAMPLE_NUMBER=42")
end
