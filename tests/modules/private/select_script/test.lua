import("private.core.base.select_script")

function _match_pattern(pattern, opt)
    pattern = pattern:gsub("([%+%.%-%^%$%(%)%%])", "%%%1")
    pattern = pattern:gsub("%*", "\001")
    pattern = pattern:gsub("\001", ".*")
    return select_script({[pattern] = true}, opt) == true
end

function test_plat_only(t)
    t:require(_match_pattern("*", {plat = "macosx"}))
    t:require(_match_pattern("macosx", {plat = "macosx"}))
    t:require(_match_pattern("macosx,linux", {plat = "macosx"}))
    t:require(_match_pattern("mac*", {plat = "macosx"}))
    t:require_not(_match_pattern("macosx", {plat = "linux"}))
    t:require_not(_match_pattern("linux", {plat = "macosx"}))
    t:require_not(_match_pattern("!macosx", {plat = "macosx"}))
    t:require_not(_match_pattern("!mac*", {plat = "macosx"}))
    t:require(_match_pattern("!macosx", {plat = "linux"}))
    t:require(_match_pattern("!mac*", {plat = "linux"}))
end

function test_arch_only(t)
end

function test_plat_arch(t)
end

function test_subhost_only(t)
end

function test_subarch_only(t)
end

function test_subarch_native(t)
end

function test_subhost_subarch(t)
end

