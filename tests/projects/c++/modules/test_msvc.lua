import("lib.detect.find_tool")
import("core.base.semver")
import("core.tool.toolchain")

function stdifcdir_support()
    if is_subhost("windows") then
        local stdifcdir
        local msvc = toolchain.load("msvc")
        if msvc and msvc:check() then
            local vcvars = msvc:config("vcvars")
            if vcvars and vcvars.VCInstallDir and vcvars.VCToolsVersion then
                stdifcdir = path.join(vcvars.VCInstallDir, "Tools", "MSVC", vcvars.VCToolsVersion, "ifc")
            end
        end
        return os.isdir(stdifcdir or "")
    end
end

function stdimport_support()
    if is_subhost("windows") then
        local stdmodulesdir
        local msvc = toolchain.load("msvc")
        if msvc and msvc:check() then
            local vcvars = msvc:config("vcvars")
            if vcvars and vcvars.VCInstallDir and vcvars.VCToolsVersion then
                stdmodulesdir = path.join(vcvars.VCInstallDir, "Tools", "MSVC", vcvars.VCToolsVersion, "modules")
            end
        end
        return os.isdir(stdmodulesdir or "")
    end
end

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
        local stdifcdir_flag = stdifcdir_support() and "--stdifcsupport=y"
        local stdimport_flag = stdimport_support() and "--stdimportsupport=y"
        if stdifcdir_flag or stdimport then
            os.execv("xmake", table.join({"f", "-c"}, stdifcdir_flag or {}, stdimport_flag or {}))
            _build()
        end
    end
end
