package("bar2")
    set_kind("library", {moduleonly = true})
    set_sourcedir(path.join(os.scriptdir(), "src"))

    on_install(function(package)
        import("package.tools.xmake").install(package, {})
    end)
