target("lcurses")
    set_kind("static")
    add_deps(get_config("runtime"))
    if is_plat("windows") and has_config("pdcurses") then
        add_deps("pdcurses")
        add_defines("XM_CONFIG_API_HAVE_CURSES", {public = true})
    elseif has_config("curses") then
        add_defines("XM_CONFIG_API_HAVE_CURSES", {public = true})
    else
        set_default(false)
    end
    add_files("lcurses.c")
    if is_plat("windows") then
        add_options("pdcurses")
        set_languages("c89")
    else
        add_options("curses")
    end

    -- suppress error: ld: archive has no table of contents file liblcurses.a
    if is_plat("iphoneos", "macosx") then
        add_arflags("-s", {force = true})
    end
