import("lib.detect.find_tool")
import("core.base.semver")

function main(t)
    local test = false
    if is_subhost("windows") then
        test = true
    elseif is_host("linux") then
        local gcc = find_tool("gcc", {version = true})
        if gcc and gcc.version and semver.compare(gcc.version, "11.0") >= 0 then
            test = true
        end
    elseif is_host("macosx") then
        local clang = find_tool("clang", {version = true})
        if clang and clang.version and semver.compare(clang.version, "14.0") >= 0 then
            test = true
        end
    end
    if test then
        os.exec("xmake")
    end
end
