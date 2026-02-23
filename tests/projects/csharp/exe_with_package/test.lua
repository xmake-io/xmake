import("lib.detect.find_tool")

function test_build(t)
    local dotnet = find_tool("dotnet")
    if dotnet then
        t:build()
    else
        return t:skip("dotnet not found")
    end
end
