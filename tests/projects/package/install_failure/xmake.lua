set_policy("network.mode", "private")

option("case", {default = "dependency"})

local case = get_config("case") or "dependency"
local fetching = case:startswith("fetch_")
local serial = case:find("serial", 1, true) or case == "optional" or case == "empty_error"
local successful = case:endswith("success")

package("abort_a")
    set_kind("binary")
    set_parallelize(not serial or case == "mixed_serial" or case == "fetch_mixed_serial")
    if fetching then
        on_fetch(function ()
            os.sleep(100)
            raise("expected fetch failure")
        end)
    end
    on_install(function (package)
        if case:startswith("process_") then
            os.runv(os.programfile(), {"lua", "-c", "raise('expected install failure')"})
        elseif case ~= "immediate" then
            os.sleep(100)
        end
        if case == "empty_error" then
            raise()
        end
        if not successful then
            raise("expected install failure")
        end
        io.writefile(path.join(package:installdir(), "passed"), "ok")
    end)
package_end()

package("abort_b")
    set_kind("binary")
    set_parallelize(not serial)
    if case:endswith("dependency") then
        add_deps("abort_a")
    end
    on_install(function (package)
        io.writefile(path.join(package:installdir(), "passed"), "ok")
        io.writefile(path.join(os.projectdir(), "b-installed"), "ok")
    end)
package_end()

if case:startswith("group") then
    add_requires("abort_a", "abort_b", {group = "alternatives"})
elseif case:endswith("dependency") then
    add_requires("abort_b")
else
    add_requires("abort_a", {optional = case == "optional"})
    add_requires("abort_b")
end
