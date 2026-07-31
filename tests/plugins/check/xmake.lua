package("foo")
    add_configs("bar", {description = "Enable bar.", default = false, type = "boolean"})
    on_install(function (package) end)
package_end()

add_requires("foo", {configs = {bar = true, baz = true, shared = true}})
add_requires("invalid_package", {configs = {abc = true}})
add_requires("invalid_package_system", {system = true, configs = {xyz = true}})
add_requires("vcpkg::invalid_package_3rd", {configs = {thirdparty_conf = true}})

namespace("ns1", function ()
    add_requires("foo~foo2", {configs = {namespaced_conf = true}})
    add_requires("invalid_ns_package")
end)

target("test")
    set_kind("phony")
