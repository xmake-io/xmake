add_rules("mode.release", "mode.debug")
add_requires("pybind11")

target("example")
    add_rules("python.module", {soabi = false})
    add_files("src/*.cpp")
    add_packages("pybind11")
    set_languages("c++11")
