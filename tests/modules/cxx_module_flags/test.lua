import("rules.c++.modules.support", {rootdir = os.programdir()})

function _target(toolname)
    return {has_tool = function (_, kind, ...)
        return kind == "cxx" and table.contains({...}, toolname)
    end}
end

function test_clang_cl_output_and_external_flags(t)
    local flags = {
        "/Fd", "producer.pdb", "-Fdconsumer.pdb",
        "/external:I", "include dir", "-external:Iother", "/external:W0", "-external:W4",
        "/MDd", "/std:c++20", "/EHsc", "/permissive-", "--target=x86_64-pc-windows-msvc"
    }
    t:are_equal(support.strip_flags(_target("clang_cl"), flags, {}), {
        "/MDd", "/std:c++20", "/EHsc", "/permissive-", "--target=x86_64-pc-windows-msvc"
    })
end

function test_clang_flags_are_unchanged(t)
    local flags = {"-g", "-O2", "-I", "include", "-isystemother", "-std=c++20", "-fno-exceptions", "-fno-rtti"}
    t:are_equal(support.strip_flags(_target("clang"), flags, {}), {"-std=c++20", "-fno-exceptions", "-fno-rtti"})
    -- clang-cl-only flags must not broaden the other drivers' filtering rules.
    t:are_equal(support.strip_flags(_target("clang"), {"-Fdkeep", "-external:Ikeep"}, {}), {"-Fdkeep", "-external:Ikeep"})
end

function test_clang_cl_strict_defines(t)
    local flags = {"/D", "PUBLIC_API=1", "-DOTHER=2", "/U", "PRIVATE_API", "-UOTHER", "/MD"}
    t:are_equal(support.strip_flags(_target("clang_cl"), flags, {}), flags)
    t:are_equal(support.strip_flags(_target("clang_cl"), flags, {strip_defines = true}), {"/MD"})
end
