add_rules("mode.release", "mode.debug")
set_languages("c++20")

-- header.hpp should be built only one time
target("aliased_headerunit")
    set_kind("binary")
    add_headerfiles("src/*.hpp")
    add_files("src/*.cpp", "src/foo/*.mpp")
