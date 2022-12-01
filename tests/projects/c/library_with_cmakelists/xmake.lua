add_rules("mode.debug", "mode.release")

package("foo")
    add_deps("cmake")
    set_sourcedir(path.join(os.scriptdir(), "foo"))
    set_policy("package.install_always", true)
    on_install(function (package)
        local configs = {}
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:debug() and "Debug" or "Release"))
        table.insert(configs, "-DBUILD_SHARED_LIBS=" .. (package:config("shared") and "ON" or "OFF"))
        import("package.tools.cmake").install(package, configs)
    end)
    on_test(function (package)
        assert(package:has_cfuncs("add", {includes = "foo.h"}))
    end)
package_end()

add_requires("foo")

target("demo")
    set_kind("binary")
    add_files("src/main.c")
    add_packages("foo")

