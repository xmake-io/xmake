
add_requires("package0", {system = false})

package("package0")
    on_load(function (package)
        package:add("defines", "PACKAGE0")
    end)
    on_install(function (package) end)

namespace("ns1", function ()

    add_requires("package1", {system = false})

    package("package1")
        on_load(function (package)
            package:add("defines", "NS1_PACKAGE1")
        end)
        on_install(function (package) end)

    target("foo")
        set_kind("static")
        add_files("src/foo.cpp")
        add_packages("package1")
        if has_package("package1") then
            add_defines("HAS_PACKAGE1")
        end

    namespace("ns2", function()

        add_requires("package2", {system = false})

        package("package2")
            on_load(function (package)
                package:add("defines", "NS2_PACKAGE2")
            end)
            on_install(function (package) end)

        target("bar")
            set_kind("static")
            add_files("src/bar.cpp")
            add_packages("package2")
            if has_package("package2") then
                add_defines("HAS_PACKAGE2")
            end
    end)

    target("test")
        set_kind("binary")
        add_deps("foo", "ns2::bar")
        add_files("src/main.cpp")
        add_packages("package0", "package1", "ns2::package2")
        on_load(function (target)
            if has_package("package0") then
                target:add("defines", "HAS_PACKAGE0")
            end
            if has_package("package1") then
                target:add("defines", "HAS_PACKAGE1")
            end
            if has_package("ns2::package2") then
                target:add("defines", "HAS_PACKAGE2")
            end
        end)
end)

