version("1.0.1")

if modes("debug") then
    symbols("debug")
    warnings("all")
    optimize("none")
    cxflags("-fsanitize=address", "-ftrapv")
end

if modes("release") then
    strip("all")
    symbols("hidden")
    cflags("-Wno-error=deprecated-declarations")
    warnings("all")
    optimize("smallest")
    vectorexts("sse2", "ssse3", "mmx")
end

if modes("profile") then
    symbols("debug")
    warnings("none")
    optimize("fastest")
end

target("hello1")
    kind("static")
    files("src/hello1/*.c")

target("hello2")
    kind("shared")
    files("$(projectdir)/src/hello2/*.c")

target("hello3")
    kind("static")
    files("src/hello3/*.c") 
    headers("src/hello3/*.h")
    headerdir("$(buildir)/inc")
    targetdir("$(buildir)/lib")
    objectdir("$(buildir)/obj")

subdirs("src/demo")
