-- the addon is installed automatically, so we can use its includes file here
includes("@addon/custom-include/check")

target("test")
    set_kind("phony")
