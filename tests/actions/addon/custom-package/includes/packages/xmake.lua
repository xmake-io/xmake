-- an addon can ship the package definitions, so that a project only needs
-- includes("@addon/custom-package/packages") and add_requires("hello-utils")
package("hello-utils")
    set_kind("library", {headeronly = true})
    set_description("the custom package of the tests")

    -- the sources are shipped by this addon, so it can be installed offline
    set_sourcedir(path.join(os.scriptdir(), "src"))

    on_install(function (package)
        os.cp("include", package:installdir())
    end)
package_end()
