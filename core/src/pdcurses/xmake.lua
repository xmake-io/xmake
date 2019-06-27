-- add target
target("pdcurses")

    -- make as a static library
    set_kind("static")

    -- add includes directory
    add_includedirs("repo", {public = true})

    -- add the common source files
    add_files("repo/pdcurses/*.c", "repo/win32/*.c") 

    -- add defines
    add_defines("PDC_WIDE")

    -- set languages
    set_languages("c89")
