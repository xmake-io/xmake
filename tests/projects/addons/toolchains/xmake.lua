add_repositories("example-toolchains-repo ./repo", {rootdir = os.scriptdir()})
add_addons("example-toolchains")

target("hello")
    set_kind("binary")
    add_files("src/main.c")
    add_toolchains("@addon/example-toolchains/settings")
