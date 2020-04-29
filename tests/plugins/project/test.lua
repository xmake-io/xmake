import("detect.sdks.find_vstudio")
import("core.project.config")
import("core.platform.platform")
import("core.platform.environment")

function test_vsxmake(t)

    if not is_subhost("windows") then
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

    -- create sln & vcxproj
    local vs = config.get("vs")
    local vstype = "vsxmake" .. vs
    os.execv("xmake", {"project", "-k", vstype, "-a", arch})
    os.cd(vstype)

    -- run msbuild
    try
    {
        function ()
            environment.enter("toolchains")
            os.exec("msbuild /P:XmakeDiagnosis=true /P:XmakeVerbose=true")
            environment.leave("toolchains")
        end,
        catch
        {
            function ()
                print("--- sln file ---")
                io.cat(projname .. "_" .. vstype .. ".sln")
                print("--- vcx file ---")
                io.cat(projname .. "/" .. projname .. ".vcxproj")
                print("--- filter file ---")
                io.cat(projname .. "/" .. projname .. ".vcxproj.filters")
                raise("msbuild failed")
            end
        }
    }

    -- clean up
    os.cd(os.scriptdir())
    os.tryrm(tempdir)
end
