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

function test_number_values_changed(t)
    local dependinfo = {values = {"moc", 1}}
    local changed = depend.is_changed(dependinfo, {values = {"moc", 2}})
    t:require(changed)
end

function test_boolean_values_changed(t)
    local dependinfo = {values = {"moc", false}}
    local changed = depend.is_changed(dependinfo, {values = {"moc", true}})
    t:require(changed)
end

function test_scalar_values_unchanged(t)
    local dependinfo = {values = {"moc", 1, true}}
    local changed = depend.is_changed(dependinfo, {values = {"moc", 1, true}})
    t:require_not(changed)
end
