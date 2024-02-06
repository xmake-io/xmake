target("b")
    add_deps("a")
    set_languages("cxxlatest")
    set_kind("moduleonly")
    
    add_files("b.mpp")
