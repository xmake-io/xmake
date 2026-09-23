import("detect.sdks.find_dotnet")

function test_build(t)
    if is_subhost("msys") then
        return t:skip("csharp not supported on msys")
    end
    local dotnet = find_dotnet()
    if dotnet and dotnet.sdkver then
        t:build()
    else
        return t:skip("dotnet sdk not found")
    end
end
