local scopekind = getenv("XMAKE_TEST_RAISE_SCOPE")

if scopekind == "target" then
    target("foo")
        raise("windows and linux only")
elseif scopekind == "package" then
    package("foo")
        raise("windows and linux only")
elseif scopekind == "rule" then
    rule("foo")
        raise("windows and linux only")
elseif scopekind == "option" then
    option("foo")
        raise("windows and linux only")
elseif scopekind == "toolchain" then
    toolchain("foo")
        raise("windows and linux only")
elseif scopekind == "task" then
    task("foo")
        raise("windows and linux only")
elseif scopekind == "namespace" then
    namespace("ns", function ()
        target("foo")
            raise("%s and %s only (%d%%)", "windows", "linux", 100)
    end)
elseif scopekind == "transition" then
    package("previous")
    package_end()
    rule("custom")
    rule_end()
    target("foo", function ()
        raise("windows and linux only")
    end)
end

print("unreachable after raise")
