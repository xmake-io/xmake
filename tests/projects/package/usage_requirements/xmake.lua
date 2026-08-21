add_rules("mode.debug", "mode.release")

add_repositories("usage-requirements-repo repo")
add_requires("usage-requirements", {system = false})

local function _has_value_from(target, name, source, expected)
    local values = target:get_from(name, source, {interface = true})
    for _, source_values in ipairs(values or {}) do
        if table.contains(table.wrap(source_values), expected) then
            return true
        end
    end
end

target("usage")
    set_kind("static")
    add_files("src/usage.cpp")
    add_packages("usage-requirements", {components = "enabled", public = true})
    before_build(function (target)
        local package = assert(target:pkg("usage-requirements"))
        assert(table.contains(package:get("vectorexts"), "avx"))
        assert(_has_value_from(target, "vectorexts", "package::*", "avx"))
        assert(_has_value_from(target, "vectorexts", "package::*", "avx2"))
        assert(not _has_value_from(target, "vectorexts", "package::*", "avx512"))
    end)

target("consumer")
    set_kind("binary")
    add_deps("usage")
    add_files("src/main.cpp")
    before_build(function (target)
        assert(_has_value_from(target, "vectorexts", "dep::usage/package::*", "avx"))
        assert(_has_value_from(target, "vectorexts", "dep::usage/package::*", "avx2"))
        assert(not _has_value_from(target, "vectorexts", "dep::usage/package::*", "avx512"))
    end)
