-- add target
target("pdcurses")

    -- make as a static library
    set_kind("static")

    -- set the object files directory
    set_objectdir("$(buildir)/.objs")

    -- add includes directory
    add_includedirs(".")

    -- add the common source files
    add_files("**.c") 

    -- add defines
    add_defines("PDC_WIDE")

    -- set languages
    set_languages("c89")
