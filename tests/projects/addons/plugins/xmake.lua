add_repositories("example-plugins-repo ./repo", {rootdir = os.scriptdir()})
add_addons("example-plugins")

target("bootstrap")
    set_kind("phony")
