import("lib.detect.find_tool")
import("core.base.semver")

function main(t)
    if is_subhost("windows") then
        os.exec("xmake f -c")
        os.exec("xmake -r")
    elseif is_host("linux") then
        local gcc = find_tool("gcc", {version = true})
        if gcc and gcc.version and semver.compare(gcc.version, "11.0") >= 0 then
            os.exec("xmake f -c")
            os.exec("xmake -r")
        end
        local clang = find_tool("clang", {version = true})
        if clang and clang.version and semver.compare(clang.version, "14.0") >= 0 then
            os.exec("xmake clean -a")
            os.exec("xmake f --toolchain=clang -c")
            os.exec("xmake -r")
        end
    end
end
