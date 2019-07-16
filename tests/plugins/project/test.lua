import("detect.sdks.find_vstudio")
import("core.project.config")
import("core.platform.platform")
import("core.platform.environment")

function test_vsxmake(t)

    if os.host() ~= "windows" then
        return t:skip("wrong host platform")
    end

    local projname = "testproj"

    local tempdir = os.tmpfile()
    os.mkdir(tempdir)
    os.cd(tempdir)

    -- create project
    os.runv("xmake", {"create", projname})
    os.cd(projname)

    -- set config
    local arch = os.getenv("platform") or "x86"
    config.set("arch", arch, {readonly = true, force = true})
    config.check()
    platform.load(config.plat())
    local vs = config.get("vs")
    environment.enter("toolchains")

    local vstype = "vsxmake" .. vs
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
                io.cat(projname .. "_" .. vstype .. ".sln")
                io.write("--- vcx file ---\n")
                io.cat(projname .. "/" .. projname .. ".vcxproj")
                io.write("--- filter file ---\n")
                io.cat(projname .. "/" .. projname .. ".vcxproj.filters")
                raise("msbuild failed")
            end
        }
    }
    environment.leave("toolchains")

    -- clean up
    os.cd(os.scriptdir())
    os.tryrm(tempdir)
end
