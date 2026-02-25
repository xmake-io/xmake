-- test add_deps with {public = false} across all target kinds
--
-- each scenario: a -> b({public = false}) -> c
-- b inherits a's public includes/defines, c does NOT
--
-- each main.c has #error if the define leaks through, so compilation
-- succeeding proves {public = false} works correctly.
-- each b.c has #error if the define is missing, proving b still inherits.

-- ============================================================
-- scenario 1: a=headeronly, b=static, c=binary
-- ============================================================
target("headeronly_a")
    set_kind("headeronly")
    add_includedirs("headeronly_dir", {public = true})
    add_defines("HAS_HEADERONLY_A=1", {public = true})

target("headeronly_b")
    set_kind("static")
    add_files("src/headeronly/b.c")
    add_deps("headeronly_a", {public = false})

target("headeronly_c")
    set_kind("binary")
    add_files("src/headeronly/main.c")
    add_deps("headeronly_b")

-- ============================================================
-- scenario 2: a=static, b=static, c=binary
-- b and c both link a transitively, but c must NOT get a's flags
-- ============================================================
target("ss_a")
    set_kind("static")
    add_files("src/static_static/a.c")
    add_includedirs("static_static_dir", {public = true})
    add_defines("HAS_SS_A=2", {public = true})

target("ss_b")
    set_kind("static")
    add_files("src/static_static/b.c")
    add_deps("ss_a", {public = false})

target("ss_c")
    set_kind("binary")
    add_files("src/static_static/main.c")
    add_deps("ss_b")

-- ============================================================
-- scenario 3: a=shared, b=static, c=binary
-- ============================================================
target("ds_a")
    set_kind("shared")
    add_files("src/shared_static/a.c")
    add_includedirs("shared_static_dir", {public = true})
    add_defines("HAS_DS_A=3", {public = true})

target("ds_b")
    set_kind("static")
    add_files("src/shared_static/b.c")
    add_deps("ds_a", {public = false})

target("ds_c")
    set_kind("binary")
    add_files("src/shared_static/main.c")
    add_deps("ds_b")

-- ============================================================
-- scenario 4: a=static, b=shared, c=binary
-- b is shared so a is linked into b; c links b dynamically
-- ============================================================
target("sd_a")
    set_kind("static")
    add_files("src/static_shared/a.c")
    add_includedirs("static_shared_dir", {public = true})
    add_defines("HAS_SD_A=4", {public = true})

target("sd_b")
    set_kind("shared")
    add_files("src/static_shared/b.c")
    add_deps("sd_a", {public = false})

target("sd_c")
    set_kind("binary")
    add_files("src/static_shared/main.c")
    add_deps("sd_b")
