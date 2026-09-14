
function test_workdir(t)
    os.tryrm("test")
    os.tryrm("build")
    os.tryrm("build2")
    os.tryrm(".xmake")
    os.exec("xmake create test")
    os.exec("xmake config -P test")
    os.exec("xmake")
    t:require(os.isdir("build"))
    t:require(os.isdir(".xmake"))
    t:require_not(os.isdir("test/build"))
    t:require_not(os.isdir("test/.xmake"))
    os.exec("xmake config -o build2")
    os.exec("xmake")
    t:require(os.isdir("build2"))
    os.tryrm("build")
    os.tryrm("build2")
    os.tryrm(".xmake")
    os.cd("test")
    os.exec("xmake create -P subtest")
    os.cd("subtest")
    os.exec("xmake config -P .")
    os.exec("xmake")
    t:require(os.isdir("build"))
    t:require(os.isdir(".xmake"))
    t:require_not(os.isdir("../build"))
    t:require_not(os.isdir("../.xmake"))
    t:require_not(os.isdir("../../build"))
    t:require_not(os.isdir("../../.xmake"))
end


-- the build directory can sit outside the working directory as well
--
-- - buildir (generated)
-- - workdir
--   - .xmake (generated)
-- - projectdir
--   - xmake.lua
--
-- @see https://github.com/xmake-io/xmake/issues/3342
function test_workdir_external_buildir(t)
    os.tryrm("test")
    os.tryrm("build")
    os.tryrm("workdir")
    os.tryrm(".xmake")
    os.exec("xmake create test")
    os.mkdir("workdir")
    os.cd("workdir")
    os.exec("xmake config -P ../test -o ../build")
    os.exec("xmake")
    t:require(os.isdir(".xmake"))
    t:require(os.isdir("../build"))
    t:require_not(os.isdir("build"))
    t:require_not(os.isdir("../test/build"))
    t:require_not(os.isdir("../test/.xmake"))
    os.cd("..")
    os.tryrm("test")
    os.tryrm("build")
    os.tryrm("workdir")
end

-- the cached project of an external working directory keeps its precedence, but it
-- should say so when the working directory is a project of its own
--
-- @see https://github.com/xmake-io/xmake/issues/7762
function test_workdir_shadowed_project(t)
    os.tryrm("projecta")
    os.tryrm("projectb")
    os.exec("xmake create projecta")
    os.exec("xmake create projectb")
    os.cd("projecta")
    try
    {
        function ()
            -- bind this working directory to the other project
            os.exec("xmake config -P ../projectb")

            -- it shadows the local xmake.lua, so it should warn about it
            local outdata, errdata = os.iorun("xmake --rebuild")
            local output = (outdata or "") .. (errdata or "")
            t:require(output:find("shadows", 1, true))

            -- the binding still wins, we only warn about it
            t:require(output:find("projectb", 1, true))

            -- and it should not warn when we ask for that project ourselves
            outdata, errdata = os.iorun("xmake --rebuild -P ../projectb")
            output = (outdata or "") .. (errdata or "")
            t:require_not(output:find("shadows", 1, true))

            -- `-P .` binds it back to the local project, so the warning goes away
            os.exec("xmake config -P .")
            outdata, errdata = os.iorun("xmake --rebuild")
            output = (outdata or "") .. (errdata or "")
            t:require_not(output:find("shadows", 1, true))
            t:require(os.isdir("build"))
        end,
        finally
        {
            -- @note try() swallows the errors if we do not re-raise them here
            function (ok, errors)
                os.cd("..")
                os.tryrm("projecta")
                os.tryrm("projectb")
                if not ok then
                    raise(errors)
                end
            end
        }
    }
end
