function test_hidden_directories(t)
    for _, name in ipairs({".gitignore", ".env", ".config.json", "..hidden"}) do
        t:are_equal(path.directory(name), ".")
        t:are_equal(path.filename(name), name)
    end
    t:are_equal(path.directory(path.new(".gitignore")), ".")
    t:are_equal(path.new(".gitignore"):directory():str(), ".")
end

function test_parent_components(t)
    t:are_equal(path.directory("dir/.gitignore"), "dir")
    t:are_equal(path.directory("dir\\.config.json"), "dir")
    t:are_equal(path.directory(".cache/file.txt"), ".cache")
    t:are_equal(path.filename("directory.with.dots/.env"), ".env")
    t:are_equal(path.filename("dir/file.tar.gz"), "file.tar.gz")
    t:are_equal(path.filename("dir/file..txt"), "file..txt")
end

function test_root_controls(t)
    t:are_equal(path.directory(""), nil)
    t:are_equal(path.directory("."), nil)
    t:are_equal(path.directory("foo"), ".")
    t:are_equal(path.filename("/"), "")
    if is_host("windows") then
        t:are_equal(path.directory("c:"), nil)
        t:are_equal(path.directory("c:\\"), nil)
        t:are_equal(path.directory("c:\\xxx"), "c:")
        t:are_equal(path.directory("c:\\xxx\\yyy"), "c:\\xxx")
        t:are_equal(path.filename("c:\\"), "")
        t:are_equal(path.filename("c:/"), "")
    else
        t:are_equal(path.directory("/"), nil)
        t:are_equal(path.directory("/tmp/file.txt"), "/tmp")
    end
end

function test_hidden_file_glob(t)
    local tmpdir = os.tmpfile()
    os.mkdir(tmpdir)
    local olddir = os.cd(tmpdir)
    local errors
    try {
        function()
            io.writefile(".gitignore", "hidden fixture\n")
            io.writefile(".config.json", "{}\n")
            t:are_equal(os.files(".git*"), {".gitignore"})
            t:are_equal(os.files(".config*"), {".config.json"})
        end,
        catch { function(err) errors = err end },
        finally { function() os.cd(olddir) end }
    }
    if errors then
        raise(errors)
    end
end
