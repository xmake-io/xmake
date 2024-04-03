target("bar")
    set_kind("$(kind)")
    add_files("src/*.cpp")
    add_headerfiles("include/(**.hpp)")
    add_includedirs("include")

