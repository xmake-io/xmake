set_project("pcxxheader_ipp")
set_languages("c17", "cxx17")
add_rules("mode.debug", "mode.release")

target("pcxxheader_ipp")
    set_kind("binary")
    set_pcxxheader("core/vendor.ipp")
    add_files("*.cpp")
