function test_cpdir(t)
    -- get mclock
    local tm = os.mclock()
    -- test cpdir
    os.mkdir("test1")
    t:require(os.exists("test1"))
    os.cp("test1","test2")
    t:require(os.exists("test2"))
    os.rmdir("test1")
    t:require_not(os.exists("test1"))
    io.writefile("test2/awd","awd")
    os.rmdir("test2")
    t:require_not(os.exists("test2"))
    -- assert mclock
    t:require(os.mclock() >= tm)
end

function test_rename(t)
    -- get mclock
    local tm = os.mclock()
    -- test rename
    os.mkdir("test1")
    t:require(os.exists("test1"))
    os.mv("test1","test2")
    t:require_not(os.exists("test1"))
    t:require(os.exists("test2"))
    os.rmdir("test2")
    t:require_not(os.exists("test2"))
    -- assert mclock
    t:require(os.mclock() >= tm)
end

function test_cp_mvdir_into_another_dir(t)
    -- get mclock
    local tm = os.mclock()
    -- test cp/mvdir into another dir
    os.mkdir("test1")
    os.mkdir("test2")
    t:require(os.exists("test1"))
    t:require(os.exists("test2"))
    os.cp("test1","test2")
    t:require(os.exists("test2/test1"))
    os.mv("test1","test2/test1")
    t:require_not(os.exists("test1"))
    t:require(os.exists("test2/test1/test1"))
    os.rmdir("test2")
    t:require_not(os.exists("test2"))
    -- assert mclock
    t:require(os.mclock() >= tm)
end

function test_cp_symlink(t)
    if is_host("windows") then
        return
    end
    os.touch("test1")
    os.ln("test1", "test2")
    t:require(os.isfile("test1"))
    t:require(os.isfile("test2"))
    t:require(os.islink("test2"))
    os.cp("test2", "test3")
    t:require(os.isfile("test3"))
    t:require(not os.islink("test3"))
    os.cp("test2", "test4", {symlink = true})
    t:require(os.isfile("test4"))
    t:require(os.islink("test4"))
    os.mkdir("dir")
    os.touch("dir/test1")
    os.cd("dir")
    os.ln("test1", "test2")
    os.cd("-")
    t:require(os.islink("dir/test2"))
    os.cp("dir", "dir2")
    t:require(not os.islink("dir2/test2"))
    os.cp("dir", "dir3", {symlink = true})
    t:require(os.islink("dir3/test2"))
    os.tryrm("test1")
    os.tryrm("test2")
    os.tryrm("test3")
    os.tryrm("test4")
    os.tryrm("dir")
    os.tryrm("dir2")
    os.tryrm("dir3")
    t:require(not os.exists("test1"))
    t:require(not os.exists("test2"))
    t:require(not os.exists("dir"))
end

function test_setenv(t)
    -- get mclock
    local tm = os.mclock()
    -- test setenv
    os.setenv("__AWD","DWA")
    t:are_equal(os.getenv("__AWD"), "DWA")
    os.setenv("__AWD","DWA2")
    t:are_equal(os.getenv("__AWD"), "DWA2")
    -- assert mclock
    t:require(os.mclock() >= tm)
end

function test_argv(t)
    t:are_equal(os.argv(""), {})
    -- $cli aa bb cc
    t:are_equal(os.argv("aa bb cc"), {"aa", "bb", "cc"})
    -- $cli aa --bb=bbb -c
    t:are_equal(os.argv("aa --bb=bbb -c"), {"aa", "--bb=bbb", "-c"})
    -- $cli "aa bb cc" dd
    t:are_equal(os.argv('"aa bb cc" dd'), {"aa bb cc", "dd"})
    -- $cli aa(bb)cc dd
    t:are_equal(os.argv('aa(bb)cc dd'), {"aa(bb)cc", "dd"})
    -- $cli aa\\bb/cc dd
    t:are_equal(os.argv('aa\\bb/cc dd'), {"aa\\bb/cc", "dd"})
    -- $cli "aa\\bb/cc dd" ee
    t:are_equal(os.argv('"aa\\\\bb/cc dd" ee'), {"aa\\bb/cc dd", "ee"})
    -- $cli "aa\\bb/cc (dd)" ee
    t:are_equal(os.argv('"aa\\\\bb/cc (dd)" ee'), {"aa\\bb/cc (dd)", "ee"})
    -- $cli -DTEST=\"hello\"
    t:are_equal(os.argv('-DTEST=\\"hello\\"'), {'-DTEST="hello"'})
    -- $cli -DTEST=\"hello\" -DTEST=\"hello\"
    t:are_equal(os.argv('-DTEST=\\"hello\\" -DTEST2=\\"hello\\"'), {'-DTEST="hello"', '-DTEST2="hello"'})
    -- $cli -DTEST="hello"
    t:are_equal(os.argv('-DTEST="hello"'), {'-DTEST=hello'})
    -- $cli -DTEST="hello world"
    t:are_equal(os.argv('-DTEST="hello world"'), {'-DTEST=hello world'})
    -- $cli -DTEST=\"hello world\"
    t:are_equal(os.argv('-DTEST=\\"hello world\\"'), {'-DTEST="hello', 'world\"'})
    -- $cli "-DTEST=\"hello world\"" "-DTEST2="\hello world2\""
    t:are_equal(os.argv('"-DTEST=\\\"hello world\\\"" "-DTEST2=\\\"hello world2\\\""'), {'-DTEST="hello world"', '-DTEST2="hello world2"'})
    -- $cli '-DTEST="hello world"' '-DTEST2="hello world2"'
    t:are_equal(os.argv("'-DTEST=\"hello world\"' '-DTEST2=\"hello world2\"'"), {'-DTEST="hello world"', '-DTEST2="hello world2"'})
    -- only split
    t:are_equal(os.argv('-DTEST="hello world"', {splitonly = true}), {'-DTEST="hello world"'})
    t:are_equal(os.argv('-DTEST="hello world" -DTEST2="hello world2"', {splitonly = true}), {'-DTEST="hello world"', '-DTEST2="hello world2"'})
end

function test_args(t)
    t:are_equal(os.args({}), "")
    t:are_equal(os.args({"aa", "bb", "cc"}), "aa bb cc")
    t:are_equal(os.args({"aa", "--bb=bbb", "-c"}), "aa --bb=bbb -c")
    t:are_equal(os.args({"aa bb cc", "dd"}), '"aa bb cc" dd')
    t:are_equal(os.args({"aa(bb)cc", "dd"}), 'aa(bb)cc dd')
    t:are_equal(os.args({"aa\\bb/cc", "dd"}), "aa\\bb/cc dd")
    t:are_equal(os.args({"aa\\bb/cc dd", "ee"}), '"aa\\\\bb/cc dd" ee')
    t:are_equal(os.args({"aa\\bb/cc (dd)", "ee"}), '"aa\\\\bb/cc (dd)" ee')
    t:are_equal(os.args({"aa\\bb/cc", "dd"}, {escape = true}), "aa\\\\bb/cc dd")
    t:are_equal(os.args('-DTEST="hello"'), '-DTEST=\\"hello\\"')
    t:are_equal(os.args({'-DTEST="hello"', '-DTEST2="hello"'}), '-DTEST=\\"hello\\" -DTEST2=\\"hello\\"')
    t:are_equal(os.args('-DTEST=hello'), '-DTEST=hello') -- irreversible
    t:are_equal(os.args({'-DTEST="hello world"', '-DTEST2="hello world2"'}), '"-DTEST=\\\"hello world\\\"" "-DTEST2=\\\"hello world2\\\""')
end

function test_async(t)
    local tmpdir = os.tmpfile() .. ".dir"
    local tmpdir2 = os.tmpfile() .. ".dir"
    io.writefile(path.join(tmpdir, "foo.txt"), "foo")
    io.writefile(path.join(tmpdir, "bar.txt"), "bar")
    local files = os.files(path.join(tmpdir, "*.txt"), {async = true})
    t:require(files and #files == 2)

    os.cp(tmpdir, tmpdir2, {async = true, detach = true})

    os.cp(tmpdir, tmpdir2, {async = true})
    t:require(os.isdir(tmpdir2))

    t:require(os.isdir(tmpdir))
    os.rm(tmpdir, {async = true})
    t:require(not os.isdir(tmpdir))

    t:require(os.isdir(tmpdir2))
    os.rm(tmpdir2, {async = true, detach = true})
end

function test_isexec(t)
    local tempdir = "temp/isexec"
    os.tryrm(tempdir)
    os.mkdir(tempdir)

    local programfile = os.programfile()
    if programfile then
        t:require(os.isexec(programfile))
    end

    local filepath = path.join(tempdir, "script")
    io.writefile(filepath, "echo test\n")

    if is_host("windows") then
        local batfile = path.join(tempdir, "a.bat")
        io.writefile(batfile, "echo test\r\n")
        t:require(os.isexec(batfile))

        local comfile = path.join(tempdir, "a.com")
        io.writefile(comfile, "12345678")
        t:require(os.isexec(comfile))

        local suffix = path.join(tempdir, "prog")
        io.writefile(suffix .. ".exe", "")
        t:require(os.isexec(suffix))

        local suffix2 = path.join(tempdir, "prog2")
        io.writefile(suffix2 .. ".com", "")
        t:require(os.isexec(suffix2))
    else
        os.vrunv("chmod", {"-x", filepath})
        t:require_not(os.isexec(filepath))
        os.vrunv("chmod", {"+x", filepath})
        t:require(os.isexec(filepath))
    end

    os.tryrm(tempdir)
end

function test_files_with_brackets(t)
    local tmpdir = os.tmpfile() .. ".dir"
    io.writefile(path.join(tmpdir, "a[1].lua"), "x")
    io.writefile(path.join(tmpdir, "a1.lua"), "x")
    -- a wildcard is required, a plain existing file is matched without converting the pattern
    local files = os.files(path.join(tmpdir, "a[1]*.lua"))
    t:are_equal(files, {path.join(tmpdir, "a[1].lua")})
    os.tryrm(tmpdir)
end

local function _with_match_callback_files(t, func)
    local root = os.tmpfile() .. ".match-callback"
    local tmproot = path.absolute(os.getenv("XMAKE_TMPDIR") or os.tmpdir())
    root = path.absolute(root)
    assert(root:startswith(tmproot .. path.sep()), "temporary fixture must stay under the test TMP directory")
    os.mkdir(root)
    local filepath = path.join(root, "callback file.txt")
    local dirpath = path.join(root, "callback dir")
    io.writefile(filepath, "callback test")
    io.writefile(path.join(root, "other.txt"), "other")
    os.mkdir(dirpath)
    func(filepath, dirpath, root)
    os.rm(root)
end

function test_match_single_path_callback(t)
    _with_match_callback_files(t, function (filepath, dirpath)
        for _, match in ipairs({
            {filepath, "f", false},
            {filepath, "a", false},
            {dirpath, "d", true},
            {dirpath, "a", true}
        }) do
            for _, with_options in ipairs({false, true}) do
                local called = {}
                local callback = function (matchedpath, isdir)
                    table.insert(called, {matchedpath, isdir})
                    return not with_options
                end
                local opt = with_options and {callback = callback} or callback
                local matches, count = os.match(match[1], match[2], opt)
                t:are_equal(matches, {match[1]})
                t:are_equal(count, 1)
                t:are_equal(called, {{match[1], match[3]}})
            end
        end
    end)
end

function test_match_single_path_callback_wrappers(t)
    _with_match_callback_files(t, function (filepath, dirpath)
        for _, match in ipairs({
            {os.files, filepath, false},
            {os.dirs, dirpath, true},
            {os.filedirs, filepath, false},
            {os.filedirs, dirpath, true}
        }) do
            for _, with_options in ipairs({false, true}) do
                local called = {}
                local callback = function (matchedpath, isdir)
                    table.insert(called, {matchedpath, isdir})
                    return true
                end
                local opt = with_options and {callback = callback} or callback
                t:are_equal(match[1](match[2], opt), {match[2]})
                t:are_equal(called, {{match[2], match[3]}})
            end
        end
    end)
end

function test_match_callback_controls(t)
    _with_match_callback_files(t, function (filepath, dirpath, root)
        for _, match in ipairs({{filepath, "f"}, {dirpath, "d"}}) do
            local matches, count = os.match(match[1], match[2])
            t:are_equal(matches, {match[1]})
            t:are_equal(count, 1)
        end
        for _, match in ipairs({{filepath, "d"}, {dirpath, "f"}, {path.join(root, "missing"), "a"}}) do
            local calls = 0
            local matches, count = os.match(match[1], match[2], function ()
                calls = calls + 1
                return true
            end)
            t:are_equal(matches, {})
            t:are_equal(count, 0)
            t:are_equal(calls, 0)
        end
        local called = {}
        local matches, count = os.match(path.join(root, "*.txt"), "f", {callback = function (matchedpath, isdir)
            t:require_not(isdir)
            table.insert(called, matchedpath)
            return true
        end})
        t:are_equal(count, 2)
        t:are_equal(called, matches)
        called = {}
        matches, count = os.match(path.join(root, "*.txt"), "f", function (matchedpath, isdir)
            t:require_not(isdir)
            table.insert(called, matchedpath)
            return false
        end)
        t:are_equal(count, 1)
        t:are_equal(called, matches)
    end)
end
