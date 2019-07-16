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
        try
        {
            function ()
                return os.iorun("msbuild /P:XmakeDiagnosis=true /P:XmakeVerbose=true")
            end,
            finally
            {
                function (ok, stdout, stderr)
                    if ok then
                        return
                    end
                    print("run msbuild for %s", vstype)
                    io.write("--- msbuild output ---")
                    io.write(stdout, "\n", stderr)
                    io.write("--- sln file ---")
                    io.write(io.readfile("c_" .. vstype .. ".sln"), "\n")
                    io.write("--- vcx file ---")
                    io.write(io.readfile("project/project.vcxproj"), "\n")
                    io.write("--- filter file ---")
                    io.write(io.readfile("project/project.vcxprok.filters"), "\n")
                    raise("msbuild failed")
                end
            }
        }
        environment.leave("toolchains")
        -- clean up
        os.cd("..")
        os.tryrm(vstype)
    end

    os.cd("..")
end
