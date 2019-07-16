import("detect.sdks.find_vstudio")
import("core.project.config")
import("core.platform.environment")

function test_vsxmake(t)

    if os.host() ~= "windows" then
        return t:skip("wrong host platform")
    end

    -- build project
    local vs = find_vstudio()
    local arch = os.getenv("platform") or "x86"

    os.cd("c")

    for name, data in pairs(vs) do
        local vstype = "vsxmake" .. name
        local path = os.getenv("path")
        os.setenv("path", data.vcvarsall[arch].path)
        environment.enter("toolchains")
        os.execv("xmake", {"project", "-k", vstype, "-a", arch})
        os.cd(vstype)
        os.exec("msbuild /t:show")
        os.exec("msbuild")
        environment.leave("toolchains")
        os.setenv("path", path)
        os.cd("..")
        os.tryrm(vstype)
    end

    os.cd("..")
end
