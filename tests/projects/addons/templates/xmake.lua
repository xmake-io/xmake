add_repositories("example-templates-repo ./repo", {rootdir = os.scriptdir()})
add_addons("example-templates")

target("bootstrap")
    set_kind("phony")
