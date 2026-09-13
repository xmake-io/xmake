-- this minimum version is older than the current xmake version, but its minor
-- number contains two digits, which broke the previous weighted version
-- comparison, e.g. v3.1.1 < v2.12.0
set_xmakever("2.12.0")

target("test")
    set_kind("phony")
