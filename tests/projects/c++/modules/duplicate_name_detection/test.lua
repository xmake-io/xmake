import("lib.detect.find_tool")
import("core.base.semver")
import("utils.ci.is_running", {alias = "ci_is_running"})

function _build()
    try {
        function() 
            if ci_is_running() then
                os.run("xmake -rvD")
            else
                os.run("xmake -r")
            end
        end,
        catch {
            function (errors)
                errors = tostring(errors)
                if not errors:find("duplicate module name detected", 1, true) then
                    raise("Modules duplicate name detection does not work\n%s", errors)
                end
            end
        }
    }
end

function can_build()
    if is_subhost("windows") then
        return true
    elseif is_subhost("msys") then
        return true
    elseif is_host("linux") then
        local gcc = find_tool("gcc", {version = true})
        if gcc and gcc.version and semver.compare(gcc.version, "11.0") >= 0 then
            return true
        end
        local clang = find_tool("clang", {version = true})
        if clang and clang.version and semver.compare(clang.version, "14.0") >= 0 then
            return true
        end
    end
end

function main(t)
    if is_subhost("windows") then
        local clang = find_tool("clang", {version = true})
        if clang and clang.version and semver.compare(clang.version, "17.0") >= 0 then
            os.exec("xmake f --toolchain=clang -c --yes --policies=build.c++.modules.std:n")
            _build()
            os.exec("xmake clean -a")
            os.exec("xmake f --toolchain=clang --runtimes=c++_shared -c --yes --policies=build.c++.modules.std:n")
            _build()
        end

        os.exec("xmake clean -a")
        os.exec("xmake f -c --yes --policies=build.c++.modules.std:n")
        _build()
    elseif is_subhost("msys") then
        os.exec("xmake f -c -p mingw --yes --policies=build.c++.modules.std:n")
        _build()
    elseif is_host("linux") then
        local gcc = find_tool("gcc", {version = true})
if gcc and gcc.version and semver.compare(gcc.version, "11.0") >= 0 then
            os.exec("xmake f -c --yes --policies=build.c++.modules.std:n")
            _build()
        end
        local clang = find_tool("clang", {version = true})
        if clang and clang.version and semver.compare(clang.version, "14.0") >= 0 then
            os.exec("xmake clean -a")
            os.exec("xmake f --toolchain=clang -c --yes --policies=build.c++.modules.std:n")
            _build()
            os.exec("xmake clean -a")
            os.exec("xmake f --toolchain=clang --runtimes=c++_shared -c --yes --policies=build.c++.modules.std:n")
            _build()
        end
    end
end
