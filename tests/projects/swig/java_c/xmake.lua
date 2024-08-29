add_rules("mode.release", "mode.debug")

-- make sure you config to an enviroment with jni.h
-- for example: xmake f -c -p android

target("example")
    set_kind('shared')
    -- set moduletype to java
    add_rules("swig.c", {moduletype = "java"})
    -- test jar build
    -- add_rules("swig.c", {moduletype = "java" , buildjar = true})
    -- use swigflags to provider package name and output path of java files
    add_files("src/example.i", {swigflags = {
        "-package",
        "com.example",
        "-outdir",
        "build/java/com/example/"
    }})
    add_files("src/example.c")
    before_build(function()
        -- ensure output path exists before running swig
        os.mkdir("build/java/com/example/")
    end)
