import("lib.detect.find_tool")
import("core.base.semver")
import("detect.sdks.find_vstudio")

function _build()
    local ci = (os.getenv("CI") or os.getenv("GITHUB_ACTIONS") or ""):lower()
    if ci == "true" then
        os.exec("xmake -rvD")
    else
        os.exec("xmake -r")
    end
end

function main(t)
    if is_subhost("windows") then
        local vs = find_vstudio()
        if vs and vs["2022"] then
            os.exec("xmake f -c --yes")
            _build()
        end
    elseif is_host("linux") then
        local gcc = find_tool("gcc", {version = true})
        if gcc and gcc.version and semver.compare(gcc.version, "11.0") >= 0 then
            -- gcc trtbd dependency detection doesn't support header units atm
            os.exec("xmake f --policies=build.c++.gcc.fallbackscanner -c --yes")
            _build()
        end
        local clang = find_tool("clang", {version = true})
        if clang and clang.version then
            if semver.compare(clang.version, "15.0") >= 0 then
                os.exec("xmake clean -a")
                -- clang-scan-deps dependency detection doesn't support header units atm
                os.exec("xmake f --toolchain=clang --policies=build.c++.clang.fallbackscanner -c")
                _build()
            -- elseif semver.compare(clang.version, "15.0") >= 0 then
            -- there is currently a bug on llvm git that prevent to build STL header units https://github.com/llvm/llvm-project/issues/58540
            -- os.exec("xmake clean -a")
            -- clang-scan-deps dependency detection doesn't support header units atm
            -- os.exec("xmake f --toolchain=clang  --policies=build.c++.modules.fallbackscanner.clang --cxxflags=\"-stdlib=libc++\" -c")
            -- _build()
            end
        end
    end
end
