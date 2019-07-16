import("detect.sdks.find_vstudio")
import("core.project.config")
import("core.platform.platform")
import("core.platform.environment")

function test_vsxmake(t)

    if os.host() ~= "windows" then
        return t:skip("wrong host platform")
    end

    -- build project
    local vs = find_vstudio()
    local arch = os.getenv("platform") or "x86"

    os.cd("c")

    for name, _ in pairs(vs) do
        -- set config
        config.set("arch", arch)
        config.set("vs", name)
        config.check()
        platform.load(config.plat())
        environment.enter("toolchains")

        local vstype = "vsxmake" .. name
        -- create sln & vcxproj
        os.execv("xmake", {"project", "-k", vstype, "-a", arch})
        os.cd(vstype)
        -- run msbuild
        os.exec("msbuild /t:show")
        os.exec("msbuild")
        environment.leave("toolchains")
        -- clean up
        os.cd("..")
        os.tryrm(vstype)
    end

    os.cd("..")
end
