package("bar")
    set_kind("headeronly")
    set_sourcedir(path.join(os.scriptdir(), "src"))

    on_install(function(package)
        import("package.tools.xmake").install(package, {})
    end)
