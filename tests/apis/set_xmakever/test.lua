-- Run the public API in a temporary project, using the actual xmake version.
-- value is a Lua expression, so invalid argument types can be tested as well.
function _check(t, value, expected_error)
    local tmpdir = os.tmpfile() .. ".dir"
    try
    {
        function ()
            os.mkdir(tmpdir)
            io.writefile(path.join(tmpdir, "xmake.lua"), "set_xmakever(" .. value .. ")\n" .. [[
target("test")
    set_kind("phony")
]])
            os.iorunv(os.programfile(), {"f", "-c", "-y"}, {curdir = tmpdir})
        end,
        finally
        {
            function (ok, errors)
                os.rmdir(tmpdir)
                if expected_error then
                    t:require_not(ok)
                    -- iorunv returns structured errors with captured output.
                    local output = type(errors) == "table" and errors.errors or errors
                    t:require(tostring(output):find(expected_error, 1, true))
                elseif not ok then
                    raise(errors)
                end
            end
        }
    }
end

function test_version_components(t)
    local version = xmake.version()
    local major, minor, patch = version:major(), version:minor(), version:patch()
    _check(t, string.format("%q", version:rawstr()))
    _check(t, '"0.0.0"')
    -- A lower major must win even when minor and patch contain many digits.
    if major > 0 then
        _check(t, string.format('"%d.999.999"', major - 1))
    end
    if minor > 0 then
        _check(t, string.format('"%d.%d.999"', major, minor - 1))
    end
    if patch > 0 then
        _check(t, string.format('"%d.%d.%d"', major, minor, patch - 1))
    end
    for _, minimum in ipairs({
        string.format("%d.0.0", major + 1),
        string.format("%d.%d.0", major, minor + 1),
        string.format("%d.%d.%d", major, minor, patch + 1),
        "999.999.999"
    }) do
        _check(t, string.format("%q", minimum), "< v" .. minimum)
    end
end

function test_prerelease_and_metadata(t)
    local version = xmake.version()
    -- Metadata must not change precedence, including on prerelease builds.
    local base = version:rawstr():gsub("%+.*$", "")
    _check(t, string.format("%q", base .. "+100"))
    _check(t, string.format("%q", base .. "+200"))
    _check(t, '"0.0.0-rc.1"')
    local newer = string.format("%d.%d.%d-rc.1", version:major(), version:minor(), version:patch() + 1)
    _check(t, string.format("%q", newer), "< v" .. newer)
end

function test_semver_formats(t)
    _check(t, '"0"')
    _check(t, '"0.0"')
    _check(t, string.format("%q", "v" .. xmake.version():rawstr():gsub("^v", "")))
end

function test_invalid_versions(t)
    _check(t, "", "set_xmakever(): no version!")
    _check(t, "nil", "set_xmakever(): no version!")
    for _, value in ipairs({"false", "true", "1", "3.1", "{}", "function () end"}) do
        _check(t, value, "set_xmakever(): invalid version, expected a string")
    end
    for _, value in ipairs({"", "invalid", "1..2", "1.2.3.4", ">=1.0.0", "1.x", "1.0.0 || 2.0.0"}) do
        _check(t, string.format("%q", value), "set_xmakever(\"" .. value .. "\"): invalid version")
    end
end

function test_accept_older_minver(t)
    os.iorunv(os.programfile(), {"f", "-c", "-y"})
end
