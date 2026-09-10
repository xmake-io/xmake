import("detect.sdks.find_vstudio")

function _detect(vc, opt)
    local old_vc = os.getenv("VCInstallDir")
    local old_vs = os.getenv("VisualStudioVersion")
    os.setenv("VCInstallDir", vc)
    os.setenv("VisualStudioVersion", "18.0")
    local result = find_vstudio(opt)
    os.setenv("VCInstallDir", old_vc)
    os.setenv("VisualStudioVersion", old_vs)
    return result["2026"].vcvarsall.x64
end

function main()
    local root = path.absolute(".xmake/msvc-fallback")
    local vc = path.join(root, "VC")
    os.mkdir(path.join(vc, "Tools/MSVC/14.51.36231"))
    os.mkdir(path.join(vc, "Tools/MSVC/14.52.36615"))
    local batch = path.join(vc, "vcvarsall.bat")
    for _, mode in ipairs({"missing_include", "missing_lib", "success"}) do
        io.writefile(batch, [[@echo off
set "VCToolsVersion=14.51.36231"
set "VCInstallDir=]] .. vc .. [["
set "INCLUDE=fixture-include"
set "LIB=fixture-lib"
echo %* | findstr /c:"-vcvars_ver=14.52" >nul
if errorlevel 1 exit /b 0
set "VCToolsVersion=14.52.36615"
]] .. (mode == "missing_include" and 'set "INCLUDE="\n' or mode == "missing_lib" and 'set "LIB="\n' or '') .. "exit /b 0\n")
        local opt = {sdkver = mode}
        local result = _detect(vc, opt)
        local expected = mode == "success" and "14.52.36615" or "14.51.36231"
        assert(result and result.VCToolsVersion == expected, mode .. ": incorrect toolset")
        assert(result.INCLUDE and result.LIB, mode .. ": incomplete environment")
        assert(opt.toolset == nil, mode .. ": mutated caller options")
    end
    local explicit = _detect(vc, {toolset="14.51.36231"})
    assert(explicit.VCToolsVersion == "14.51.36231", "explicit toolset overridden")
end
