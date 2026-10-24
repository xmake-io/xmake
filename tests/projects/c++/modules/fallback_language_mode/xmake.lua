add_rules("mode.debug", "mode.release")
set_languages("c++20")

target("fallback_language_mode")
    set_kind("binary")
    add_files("src/*.cpp", "src/*.mpp")
