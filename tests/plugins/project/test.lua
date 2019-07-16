import("detect.sdks.find_vstudio")
import("core.project.config")
import("core.platform.platform")
import("core.platform.environment")

function test_vsxmake(t)

    if os.host() ~= "windows" then
        return t:skip("wrong host platform")
    end

    local projname = "testproj"

    -- create project
    os.runv("xmake", {"create", projname})

    -- build project
    local vs = find_vstudio()
    local arch = os.getenv("platform") or "x86"

    os.cd(projname)

    for name, _ in pairs(vs) do
        if tonumber(name) >= 2010 then
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
                    os.exec("msbuild /P:XmakeDiagnosis=true /P:XmakeVerbose=true")
                end,
                catch
                {
                    function ()
                        io.write("--- sln file ---\n")
                        io.write(io.readfile(projname .. "_" .. vstype .. ".sln"), "\n")
                        io.write("--- vcx file ---\n")
                        io.write(io.readfile(projname .. "/" .. projname .. ".vcxproj"), "\n")
                        io.write("--- filter file ---\n")
                        io.write(io.readfile(projname .. "/" .. projname .. ".vcxproj.filters"), "\n")
                        raise("msbuild failed")
                    end
                }
            }
            environment.leave("toolchains")
            -- clean up
            os.cd("..")
            os.tryrm(vstype)
        end
    end

    -- clean up
    os.cd("..")
    os.tryrm(projname)
end
