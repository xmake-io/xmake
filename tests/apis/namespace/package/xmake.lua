
add_requires("package0")

package("package0")
    on_fetch(function (package)
        return {defines = "PACKAGE0"}
    end)

namespace("ns1", function ()

    add_requires("package1")

    package("package1")
        on_fetch(function (package)
            return {defines = "NS1_PACKAGE1"}
        end)

    target("foo")
        set_kind("static")
        add_files("src/foo.cpp")
        add_packages("package1")

    namespace("ns2", function()

        add_requires("package2")

        package("package2")
            on_fetch(function (package)
                return {defines = "NS2_PACKAGE2"}
            end)

        target("bar")
            set_kind("static")
            add_files("src/bar.cpp")
            add_packages("package2")
    end)

    target("test")
        set_kind("binary")
        add_deps("foo", "ns2::bar")
        add_files("src/main.cpp")
        add_packages("package0", "package1", "ns2::package2")
end)

