 
-- add tbox package
option("tbox")

    -- show menu
    set_showmenu(true)

    -- set category
    set_category("package")

    -- set description
    set_description("The tbox package")

    -- set language: c99, c++11
    set_languages("c99", "cxx11")

    -- add defines to config.h if checking ok
    add_defines_h_if_ok("$(prefix)_PACKAGE_HAVE_TBOX")

    -- add links for checking
    add_links("tbox")

    -- add link directories
    add_linkdirs("lib/$(mode)/$(plat)/$(arch)")

    -- add c includes for checking
    add_cincludes("tbox/tbox.h")

    -- add include directories
    add_includedirs("inc/$(plat)", "inc")
