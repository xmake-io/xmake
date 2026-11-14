import("core.tools.gcc.has_flags")
import("core.base.semver")
import("lib.detect.find_tool")

local reflection_error = "cc1plus: error: '-freflection' only supported with '-std=c++26' or '-std=gnu++26'"

function _make_compiler(errors, opt)
    opt = opt or {}
    local script = os.tmpfile() .. ".sh"
    local body = "#!/bin/sh\necho \"$@\" >> \"$0.log\"\n"
    if not opt.always_fail then
        body = body .. [[
std=
for arg in "$@"; do
    case "$arg" in
        -std=*) std="$arg" ;;
    esac
done
if [ "$std" = "-std=c++26" ]; then
    exit 0
fi
]]
    end
    io.writefile(script, body .. "printf '%s\\n' \"" .. errors .. "\" >&2\nexit 1\n")
    os.vrunv("chmod", {"+x", script})
    return script
end

function _check_flags(script, flags)
    local ok, errors = has_flags(flags, {program = script, flagkind = "cxxflags", toolkind = "cxx", tryrun = true})
    local lines = table.to_array(io.lines(script .. ".log"))
    os.tryrm(script)
    os.tryrm(script .. ".log")
    return ok, errors, lines
end

function test_retry_succeeds(t)
    if is_host("windows") then
        return t:skip("needs sh")
    end
    local script = _make_compiler(reflection_error)
    local ok, _, lines = _check_flags(script, {"-freflection"})
    t:require(ok)
    t:are_equal(#lines, 2)
    t:require(lines[2]:startswith("-std=c++26 "))
end

function test_retry_succeeds_utf8(t)
    if is_host("windows") then
        return t:skip("needs sh")
    end
    local errors = "cc1plus: error: \226\128\152-freflection\226\128\153 only supported with \226\128\152-std=c++26\226\128\153 or \226\128\152-std=gnu++26\226\128\153"
    local script = _make_compiler(errors)
    local ok, _, lines = _check_flags(script, {"-freflection"})
    t:require(ok)
    t:are_equal(#lines, 2)
end

function test_retry_fails(t)
    if is_host("windows") then
        return t:skip("needs sh")
    end
    local script = _make_compiler(reflection_error, {always_fail = true})
    local ok, errors, lines = _check_flags(script, {"-freflection"})
    t:require_not(ok)
    t:require(errors:find("only supported with", 1, true))
    t:are_equal(#lines, 2)
end

function test_unrelated_error(t)
    if is_host("windows") then
        return t:skip("needs sh")
    end
    local script = _make_compiler("cc1plus: error: unrecognized command-line option '-freflection'", {always_fail = true})
    local ok, _, lines = _check_flags(script, {"-freflection"})
    t:require_not(ok)
    t:are_equal(#lines, 1)
end

function test_user_std_wins(t)
    if is_host("windows") then
        return t:skip("needs sh")
    end
    local script = _make_compiler(reflection_error)
    local ok, _, lines = _check_flags(script, {"-freflection", "-std=c++20"})
    t:require_not(ok)
    t:are_equal(#lines, 2)
    t:require(lines[2]:startswith("-std=c++26 -freflection -std=c++20 "))
end

function test_reflection(t)
    local gxx = find_tool("g++", {version = true})
    if not gxx or gxx.name ~= "gxx" or not gxx.version or semver.compare(gxx.version, "16.0") < 0 then
        return t:skip("needs g++ 16 or newer")
    end
    local ok = has_flags({"-freflection"}, {program = gxx.program, flagkind = "cxxflags", toolkind = "cxx", tryrun = true})
    t:require(ok)
end
