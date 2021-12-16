add_rules("mode.debug", "mode.release")

add_requires("cmake::ZLIB", {system = true})
add_requires("cmake::LibXml2", {system = true})
add_requires("cmake::Boost", {system = true,
    configs = {components = {"regex", "system"}, presets = {Boost_USE_STATIC_LIB = true}}})
target("test")
    set_kind("binary")
    add_files("src/*.cpp")
    add_packages("cmake::ZLIB", "cmake::Boost", "cmake::LibXml2")


