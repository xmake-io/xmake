package("foo")
    add_deps("zlib >=v1.2.13")
package_end()

package("bar")
    add_deps("zlib")
package_end()

package("test")
    add_deps("foo", "bar")
package_end()

add_requires("test")

target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("test")
