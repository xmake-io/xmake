
package("foo")
    add_deps("zlib >=1.2.13")
    set_policy("package.install_locally", true)
    on_install(function () end)
package_end()

package("bar")
    add_deps("zlib 1.2.x")
    set_policy("package.install_locally", true)
    on_install(function () end)
package_end()

package("zoo")
    set_policy("package.install_locally", true)
    on_install(function () end)
package_end()

package("test")
    add_deps("foo", "bar", "zoo")
    set_policy("package.install_locally", true)
    on_install(function () end)
package_end()

set_policy("package.sync_requires_to_deps", true)

add_requires("test")
add_requires("zlib >=1.2.13", {system = false, configs = {shared = true}})

target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("test")
