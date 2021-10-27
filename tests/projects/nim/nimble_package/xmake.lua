add_rules("mode.debug", "mode.release")

add_requires("nimble::zip")

target("test")
    set_kind("binary")
    add_files("src/main.nim")
    add_packages("nimble::zip")
