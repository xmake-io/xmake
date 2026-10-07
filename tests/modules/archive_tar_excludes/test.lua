import("lib.detect.find_tool")
import("utils.archive.extract")

function _test_excludes(t, excludes)
    local tar = find_tool("tar")
    if not tar then
        return t:skip("tar not found")
    end
    local root = os.tmpfile() .. ".dir"
    local inputdir = path.join(root, "input")
    local outputdir = path.join(root, "output")
    local archivefile = path.join(root, "files.tar.gz")
    try {
        function ()
            os.mkdir(inputdir)
            io.writefile(path.join(inputdir, "keep.txt"), "keep\n")
            io.writefile(path.join(inputdir, "skip-a.txt"), "a\n")
            io.writefile(path.join(inputdir, "skip-b.txt"), "b\n")
            os.vrunv(tar.program, {"-czf", archivefile, "-C", inputdir,
                                  "keep.txt", "skip-a.txt", "skip-b.txt"})
            extract(archivefile, outputdir, {excludes = excludes})
            t:are_equal(io.readfile(path.join(outputdir, "keep.txt")), "keep\n")
            t:require(not os.isfile(path.join(outputdir, "skip-a.txt")))
            if #excludes > 1 then
                t:require(not os.isfile(path.join(outputdir, "skip-b.txt")))
            else
                t:are_equal(io.readfile(path.join(outputdir, "skip-b.txt")), "b\n")
            end
        end,
        finally {
            function (ok, errors)
                os.rm(root)
                if not ok then
                    raise(errors)
                end
            end
        }
    }
end

function test_multiple_excludes(t)
    return _test_excludes(t, {"skip-a.txt", "skip-b.txt"})
end

function test_single_exclude(t)
    return _test_excludes(t, {"skip-a.txt"})
end
