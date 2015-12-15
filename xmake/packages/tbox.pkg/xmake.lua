 
-- add tbox package
add_option("tbox")

    -- show menu
    set_option_showmenu(true)

    -- set category
    set_option_category("package")

    -- set description
    set_option_description("The tbox package")

    -- set language: c99, c++11
    set_option_languages("c99", "cxx11")

    -- add defines to config.h if checking ok
    add_option_defines_h_if_ok("$(prefix)_PACKAGE_HAVE_TBOX")

    -- add links for checking
    add_option_links("tbox")

    -- add link directories
    add_option_linkdirs("lib/$(mode)/$(plat)/$(arch)")

    -- add c includes for checking
    add_option_cincludes("tbox/tbox.h")

    -- add include directories
    add_option_includedirs("inc/$(plat)", "inc")
