add_rules("mode.debug", "mode.release")

package("dpdk")
    set_sourcedir(path.join(os.scriptdir(), "../../3rd/dpdk"))
    on_install("linux", function (package)
        import("package.tools.xmake").install(package)
    end)
    on_test(function (package)
        assert(package:has_cxxincludes("add.h"))
    end)
package_end()

add_includedirs("src")

add_requires("dpdk")

target("spdk_mul")
   set_kind("static")
   add_files("src/mul.cc")
   add_headerfiles("src/*.h")
   add_packages("dpdk")

