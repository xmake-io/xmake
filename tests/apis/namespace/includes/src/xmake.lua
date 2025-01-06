namespace("ns2", function ()
    add_defines("NS2_ROOT")
    target("bar")
        set_kind("static")
        add_files("bar.cpp")
        add_defines("BAR")
end)

