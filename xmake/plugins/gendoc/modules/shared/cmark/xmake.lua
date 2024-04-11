add_rules("mode.debug", "mode.release")

set_languages("c11")

target("libcmark")
    set_version("0.31.0")
    set_kind("static")
    add_files("src/blocks.c",
              "src/buffer.c",
              "src/cmark.c",
              "src/cmark_ctype.c",
              "src/commonmark.c",
              "src/houdini_href_e.c",
              "src/houdini_html_e.c",
              "src/houdini_html_u.c",
              "src/html.c",
              "src/inlines.c",
              "src/iterator.c",
              "src/latex.c",
              "src/man.c",
              "src/node.c",
              "src/references.c",
              "src/render.c",
              "src/scanners.c",
              "src/utf8.c",
              "src/xml.c")
    add_headerfiles("src/*.h")
    add_configfiles("src/cmark_version.h.in")
    set_configdir("src")
    add_includedirs("src", {public = true})

target("cmark")
    add_rules("module.shared")
    add_deps("libcmark")
    add_files("cmark_module.c")
