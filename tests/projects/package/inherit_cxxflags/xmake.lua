add_rules("mode.debug", "mode.release")
set_languages("c++17")

for _, name in ipairs({"public", "private", "interface"}) do
    package("test_" .. name .. "_cxxflags")
        on_load(function (package)
            package:add("cxxflags", "-DPACKAGE_" .. name:upper())
        end)
        on_install(function (package) end)
    package_end()
end
add_requires("test_public_cxxflags", "test_private_cxxflags", "test_interface_cxxflags", {system = false})

target("producer")
    set_kind("static")
    add_files("src/producer.cpp")
    add_packages("test_public_cxxflags", {public = true})
    add_packages("test_private_cxxflags")
    add_packages("test_interface_cxxflags", {interface = true})

target("bridge")
    set_kind("phony")
    add_deps("producer")

target("consumer")
    set_kind("binary")
    add_deps("bridge")
    add_files("src/main.cpp")

target("no_inherit")
    set_kind("binary")
    add_deps("producer", {inherit = false})
    add_files("src/no_inherit.cpp")

target("override_producer")
    set_kind("phony")
    add_packages("test_public_cxxflags", {public = true, cxxflags = "-DPACKAGE_OVERRIDE"})

target("override_consumer")
    set_kind("binary")
    add_deps("override_producer")
    add_files("src/override.cpp")
