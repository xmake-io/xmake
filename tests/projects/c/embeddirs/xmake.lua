add_rules("mode.debug", "mode.release")

set_languages("c23")

target("embeddirs")
    set_kind("binary")
    add_files("src/*.c")
    add_embeddirs("assets")

