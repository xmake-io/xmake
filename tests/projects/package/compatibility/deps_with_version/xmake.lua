package("foo")
    add_deps("zlib >=1.2.13")
    on_install(function () end)
package_end()

package("bar")
    add_deps("zlib 1.2.x")
--    add_deps("libpng dev")
    on_install(function () end)
package_end()

package("zoo")
    add_deps("libpng master")
    on_install(function () end)
package_end()

package("test")
    add_deps("foo", "bar", "zoo")
    on_install(function () end)
package_end()

add_requires("test")

target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("test")
