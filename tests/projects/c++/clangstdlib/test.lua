import("lib.detect.find_tool")

function main(t)
    local clang = find_tool("clang")
    if clang then
        os.exec("xmake f --toolchain=clang --policies=build.c++.clang.libcxx -c")
        local ci = (os.getenv("CI") or os.getenv("GITHUB_ACTIONS") or ""):lower()
        if ci == "true" then
            os.exec("xmake -rvD")
        else
            os.exec("xmake -r")
        end
    end
end
