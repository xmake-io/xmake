package("usage-requirements")
    set_kind("library", {headeronly = true})
    set_sourcedir(path.join(os.scriptdir(), "src"))

    add_components("enabled")
    add_components("disabled")

    on_load(function (package)
        package:add("vectorexts", "avx")
    end)

    on_component("enabled", function (package, component)
        component:add("vectorexts", "avx2")
    end)

    on_component("disabled", function (package, component)
        component:add("vectorexts", "avx512")
    end)

    on_install(function (package)
        os.cp("README.md", package:installdir())
    end)
