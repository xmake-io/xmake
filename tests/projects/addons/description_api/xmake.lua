add_repositories("example-description-api-repo ./repo", {rootdir = os.scriptdir()})
add_addons("example-description-api")

local projectdir = os.scriptdir()

-- The addon invokes this description-domain callback after registering its APIs.
-- The first project scan can therefore finish before the addon is installed.
function example_configure_profiles()
    example_profile("demo")
        set_message("hello from a custom scope")
        add_tags("portable", "reusable")

    target("hello")
        set_kind("binary")
        add_files(path.join(projectdir, "src/main.c"))
        set_example_profile("demo")
        add_rules("@addon/example-description-api/message")
end

includes("@addon/example-description-api/apis")
