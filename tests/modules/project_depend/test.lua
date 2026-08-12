import("core.project.depend")

function test_nested_values_append(t)
    local dependinfo = {values = {{"clang", "-m64"}}}
    local changed = depend.is_changed(dependinfo, {values = {{"clang", "-m64", "-DFEATURE_ON"}}})
    t:require(changed)
end

function test_nested_values_remove(t)
    local dependinfo = {values = {{"clang", "-m64", "-DFEATURE_ON"}}}
    local changed = depend.is_changed(dependinfo, {values = {{"clang", "-m64"}}})
    t:require(changed)
end

function test_nested_values_unchanged(t)
    local dependinfo = {values = {{"clang", "-m64", "-DFEATURE_ON"}}}
    local changed = depend.is_changed(dependinfo, {values = {{"clang", "-m64", "-DFEATURE_ON"}}})
    t:require_not(changed)
end
