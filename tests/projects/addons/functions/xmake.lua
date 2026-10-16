add_repositories("example-functions-repo ./repo", {rootdir = os.scriptdir()})
add_addons("example-functions")

local projectdir = os.scriptdir()

-- This callback runs in the description domain, after the addon defines its helper.
function example_configure_targets()
    example_console("hello", path.join(projectdir, "src/main.c"))

    -- The generated target can still be customized with ordinary Xmake APIs.
    target("hello")
        add_defines("EXAMPLE_NUMBER=42")
end

includes("@addon/example-functions/targets")
