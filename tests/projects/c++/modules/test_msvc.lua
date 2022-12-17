import("lib.detect.find_tool")
import("core.base.semver")
import("core.tool.toolchain")

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
        local msvc = toolchain.load("msvc")
        if msvc and msvc:check() then
            local vcvars = msvc:config("vcvars")
            if vcvars and vcvars.VCInstallDir and vcvars.VCToolsVersion and semver.compare(vcvars.VCToolsVersion, "14.35") then
                local stdmodulesdir = path.join(vcvars.VCInstallDir, "Tools", "MSVC", vcvars.VCToolsVersion, "modules")
                if os.isdir(stdmodulesdir) then
                    os.exec("xmake f -c")
                    _build()
                end
            end
        end
    end
end
