import("rules.c++.modules.clang.support", {rootdir = os.programdir()})

function test_include_paths(t)
    local flags = {
        "-Ijoined", "-I", "local headers", "/Ijoined", "/I", "local headers",
        "-external:Ijoined", "-external:I", "system headers",
        "/external:Ijoined", "/external:I", "system headers",
        "-isystemjoined", "-isystem", "system headers",
        "-iquotejoined", "-iquote", "quote headers",
        "-idirafterjoined", "-idirafter", "after headers",
        "/MDd", "-O2", "-g", "/EHsc", "-std=c++20", "--target=x86_64-pc-windows-msvc",
        "-fmodule-file=dep=dep.pcm", "-DKEEP=1", "-Werror=unused-command-line-argument"
    }
    local original = table.clone(flags)
    t:are_equal(support.strip_pcm_includedirs(flags), {
        "/MDd", "-O2", "-g", "/EHsc", "-std=c++20", "--target=x86_64-pc-windows-msvc",
        "-fmodule-file=dep=dep.pcm", "-DKEEP=1", "-Werror=unused-command-line-argument"
    })
    t:are_equal(flags, original)
end

function test_other_flags(t)
    local flags = {"-include", "forced.h", "-include-pch", "prefix.pch", "/FIforced.h", "-Werror"}
    t:are_equal(support.strip_pcm_includedirs(flags), flags)
    t:are_equal(support.strip_pcm_includedirs({}), {})
end
