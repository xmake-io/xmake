add_repositories("example-description-api-repo ./repo", {rootdir = os.scriptdir()})
add_addons("example-description-api")
includes("@addon/example-description-api/apis")

-- Skip addon APIs during the first scan, before automatic installation.
if example_profile then
    example_profile("demo")
        set_message("hello from a custom scope")
        add_tags("portable", "reusable")

    target("hello")
        set_kind("binary")
        add_files("src/main.c")
        set_example_profile("demo")
        add_rules("@addon/example-description-api/message")
end
