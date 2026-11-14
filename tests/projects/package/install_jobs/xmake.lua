set_policy("network.mode", "private")
option("case", {default = "parallel"})

local case = get_config("case") or "parallel"
local names = {"jobs_a", "jobs_b", "jobs_c", "jobs_d", "jobs_e", "jobs_f"}
if case == "mixed" then
    names = {"jobs_c", "jobs_a", "jobs_b", "jobs_d", "jobs_e", "jobs_f"}
elseif case == "mixed_last" then
    names = {"jobs_a", "jobs_b", "jobs_d", "jobs_e", "jobs_f", "jobs_c"}
end
for _, name in ipairs(names) do
    local serial = case == "serial" or (case:startswith("mixed") and name == "jobs_c")
        or (case == "mixed_multiple" and name == "jobs_e")
    package(name)
        set_kind("binary")
        set_parallelize(not serial)
        if case == "diamond" or case == "mixed_dependency" then
            if name == "jobs_b" or name == "jobs_c" then
                add_deps("jobs_a")
            elseif name == "jobs_d" then
                add_deps("jobs_b", "jobs_c")
            end
        elseif (case == "optional" or case == "installed") and name == "jobs_b" then
            add_deps("jobs_a", {optional = case == "optional"})
        end
        if case == "schemes" and name == "jobs_a" then
            add_schemes("first", "second")
        end
        on_fetch(function (package)
            if not package:manifest_load() and not package:data("fetch_observed") then
                package:data_set("fetch_observed", true)
                local events = import("events", {rootdir = package:scriptdir()})
                events.record("fetch", "start", package)
                os.sleep(100)
                events.record("fetch", "finish", package)
            end
            if case == "installed" and package:name() == "jobs_a" then
                return {program = "already-installed"}
            end
        end)
        on_install(function (package)
            local events = import("events", {rootdir = package:scriptdir()})
            events.record("install", "start", package)
            os.sleep(100)
            if case == "schemes" and package:name() == "jobs_a" then
                local scheme = package:current_scheme():name()
                io.writefile(path.join(os.projectdir(), "scheme-" .. scheme), "ok")
                if scheme == "first" then
                    events.record("install", "finish", package)
                    raise("expected first scheme failure")
                end
            elseif case == "optional" and package:name() == "jobs_a" then
                events.record("install", "finish", package)
                raise("expected optional failure")
            end
            io.writefile(path.join(package:installdir(), "passed"), "ok")
            events.record("install", "finish", package)
        end)
    package_end()
end

if case == "optional" then
    add_requires("jobs_b", "jobs_c", "jobs_d", "jobs_e", "jobs_f")
else
    add_requires(table.unpack(names))
end
