add_rules("mode.debug", "mode.release")
set_languages("cxx11")

-- Target 1: main executable
target("main")
    set_kind("binary")
    set_pcxxheader("src/common.h")
    add_files("src/main.cpp")
    add_deps("lib1", "lib2")

-- Target 2: static library 1
target("lib1")
    set_kind("static")
    set_pcxxheader("src/lib1_pch.h")
    add_files("src/lib1.cpp")

-- Target 3: static library 2
target("lib2")
    set_kind("static")
    set_pcxxheader("src/lib2_pch.h")
    add_files("src/lib2.cpp")

-- Target 4: another executable with different PCH
target("tool")
    set_kind("binary")
    set_pcxxheader("src/tool_pch.h")
    add_files("src/tool.cpp")

-- Target 5: executable without PCH
target("simple")
    set_kind("binary")
    add_files("src/simple.cpp")

-- Target 6: executable without PCH but depends on PCH library
target("consumer")
    set_kind("binary")
    add_files("src/consumer.cpp")
    add_deps("lib1")

-- Target 7: PCH with .ipp extension
target("test_ipp_pch")
    set_kind("binary")
    set_pcxxheader("src/pch_test.ipp")
    add_files("src/test_ipp.cpp")

-- Target 8: PCH with .inc extension  
target("test_inc_pch")
    set_kind("binary")
    set_pcxxheader("src/pch_test.inc")
    add_files("src/test_inc.cpp")

-- Target 9: PCH with .inl extension
target("test_inl_pch")
    set_kind("binary")
    set_pcxxheader("src/pch_test.inl")
    add_files("src/test_inl.cpp")

-- Target 10: PCH with .tcc extension
target("test_tcc_pch")
    set_kind("binary")
    set_pcxxheader("src/pch_test.tcc")
    add_files("src/test_tcc.cpp")

-- Target 11: PCH with .tpl extension
target("test_tpl_pch")
    set_kind("binary")
    set_pcxxheader("src/pch_test.tpl")
    add_files("src/test_tpl.cpp")
