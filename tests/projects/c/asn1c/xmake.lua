add_rules("mode.debug", "mode.release")
add_requires("asn1c")

target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_files("src/*.asn1")
    add_rules("asn1c")
    add_packages("asn1c")
