import("lib.detect.find_tool")
import("core.base.semver")

function _build()
    local ci = (os.getenv("CI") or os.getenv("GITHUB_ACTIONS") or ""):lower()
    if ci == "true" then
        os.exec("xmake -rvD")
    else
        os.exec("xmake -r")
    end
end

function main(t)
    local clang = find_tool("clang")
    if clang then
        os.exec("xmake clean -a")
        os.exec("xmake f --toolchain=clang -c")
        _build()
        os.exec("xmake clean -a")
        os.exec("xmake f --toolchain=clang --cxxstl=\"libc++\" -c")
        _build()
        os.exec("xmake clean -a")
        os.exec("xmake f --toolchain=clang --cxxstl=\"libstdc++\" -c")
        _build()
        if is_plat("windows") then
            os.exec("xmake clean -a")
            os.exec("xmake f --toolchain=clang --cxxstl=\"msstl\" -c")
            _build()
        end
        os.exec("xmake clean -a")
        os.exec("xmake f --toolchain=llvm -c")
        _build()
        os.exec("xmake clean -a")
        os.exec("xmake f --toolchain=llvm --cxxstl=\"libc++\" -c")
        _build()
        os.exec("xmake clean -a")
        os.exec("xmake f --toolchain=llvm --cxxstl=\"libstdc++\" -c")
        _build()
        if is_plat("windows") then
            os.exec("xmake clean -a")
            os.exec("xmake f --toolchain=llvm --cxxstl=\"msstl\" -c")
            _build()
        end
    end
end
