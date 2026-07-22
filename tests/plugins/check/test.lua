function test_api_package_requires(t)
    local outdata = os.iorunv("xmake", {"check", "api.package.requires"})

    -- locally-defined package is found
    t:require_not(outdata:find("unknown package 'foo'", 1, true))

    -- invalid package is reported
    t:require(outdata:find("unknown package 'invalid_package'", 1, true))

    -- invalid namespace package is reported
    t:require(outdata:find("unknown package 'invalid_ns_package'", 1, true))

    -- system package is skipped
    t:require_not(outdata:find("unknown package 'invalid_package_system'", 1, true))

    -- 3rd-party package is skipped
    t:require_not(outdata:find("unknown package 'vcpkg::invalid_package_3rd'", 1, true))

    -- invalid configs are flagged in add_requires
    t:require(outdata:find("unknown config value 'baz'", 1, true))

    -- valid config and builtin configs are not flagged
    t:require_not(outdata:find("unknown config value 'bar'", 1, true))
    t:require_not(outdata:find("unknown config value 'shared'", 1, true))

    -- configs on an invalid package are skipped
    t:require_not(outdata:find("'abc'", 1, true))

    -- invalid configs on a system package are flagged
    t:require(outdata:find("unknown config value 'xyz'", 1, true))

    -- configs on a 3rd-party package are skipped
    t:require_not(outdata:find("'thirdparty_conf'", 1, true))

    -- invalid configs inside a namespace are flagged
    t:require(outdata:find("unknown config value 'namespaced_conf'", 1, true))
end
