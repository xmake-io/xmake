import("utils.archive.archive")
import("utils.archive.extract")

function test_extract_empty_files(t)
    local root = os.tmpfile() .. ".dir"
    local inputdir = path.join(root, "input")
    local outputdir = path.join(root, "output")
    local workdir = path.join(root, "work")
    local archivefile = path.join(root, "files.xmz")
    os.mkdir(workdir)
    io.writefile(path.join(inputdir, "empty.txt"), "")
    io.writefile(path.join(inputdir, "nested", "empty.txt"), "")
    io.writefile(path.join(inputdir, "data.txt"), "hello xmz")
    archive(archivefile, {inputdir}, {curdir = inputdir})
    local olddir = os.cd(workdir)
    try {function ()
        extract(archivefile, outputdir)
        t:require(os.isfile(path.join(outputdir, "empty.txt")))
        t:are_equal(os.filesize(path.join(outputdir, "empty.txt")), 0)
        t:require(os.isfile(path.join(outputdir, "nested", "empty.txt")))
        t:are_equal(os.filesize(path.join(outputdir, "nested", "empty.txt")), 0)
        t:are_equal(io.readfile(path.join(outputdir, "data.txt")), "hello xmz")
        t:require(not os.isfile(path.join(workdir, "empty.txt")))
        t:require(not os.isfile(path.join(workdir, "nested", "empty.txt")))
    end, finally {function (ok, errors)
        os.cd(olddir)
        os.rm(root)
        if not ok then
            raise(errors)
        end
    end}}
end

function test_extract_empty_file_overwrites_contents(t)
    local root = os.tmpfile() .. ".dir"
    local inputdir = path.join(root, "input")
    local outputdir = path.join(root, "output")
    local workdir = path.join(root, "work")
    local archivefile = path.join(root, "files.xmz")
    os.mkdir(workdir)
    io.writefile(path.join(inputdir, "empty.txt"), "")
    io.writefile(path.join(outputdir, "empty.txt"), "old contents")
    archive(archivefile, {inputdir}, {curdir = inputdir})
    local olddir = os.cd(workdir)
    try {function ()
        extract(archivefile, outputdir)
        t:are_equal(os.filesize(path.join(outputdir, "empty.txt")), 0)
    end, finally {function (ok, errors)
        os.cd(olddir)
        os.rm(root)
        if not ok then
            raise(errors)
        end
    end}}
end
