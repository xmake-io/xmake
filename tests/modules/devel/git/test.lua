import("devel.git")


function test_asgiturl(t)
    t:are_equal(git.asgiturl("http://github.com/a/b"), "https://github.com/a/b.git")
    t:are_equal(git.asgiturl("http://github.com/a/b/"), "https://github.com/a/b.git")
    t:are_equal(git.asgiturl("HTTP://github.com//a/b/"), "https://github.com/a/b.git")
    t:are_equal(git.asgiturl("http://github.com//a/b/s"), nil)
    t:are_equal(git.asgiturl("https://github.com/a/b"), "https://github.com/a/b.git")
    t:are_equal(git.asgiturl("https://github.com/a/b.git"), "https://github.com/a/b.git")
    t:are_equal(git.asgiturl("HTTPS://GITHUB.com/a/b.git.git"), "https://github.com/a/b.git.git")

    t:are_equal(git.asgiturl("github:a/b"), "https://github.com/a/b.git")
    t:are_equal(git.asgiturl("github:a/b.git"), "https://github.com/a/b.git.git")
    t:are_equal(git.asgiturl("GitHub://a/b/"), "https://github.com/a/b.git")
    t:are_equal(git.asgiturl("github:a/b/c"), nil)
end

function _make_repository(git)
    local repodir = os.tmpfile() .. ".repo"
    os.mkdir(repodir)
    os.vrunv(git.program, {"-C", repodir, "init"})
    os.vrunv(git.program, {"-C", repodir, "symbolic-ref", "HEAD", "refs/heads/master"})
    os.vrunv(git.program, {"-C", repodir, "config", "user.name", "Xmake Test"})
    os.vrunv(git.program, {"-C", repodir, "config", "user.email", "test@example.invalid"})
    os.vrunv(git.program, {"-C", repodir, "remote", "add", "origin", "https://example.invalid/project.git"})
    io.writefile(path.join(repodir, "tracked.txt"), "committed\n")
    os.vrunv(git.program, {"-C", repodir, "add", "tracked.txt"})
    os.vrunv(git.program, {"-C", repodir, "-c", "commit.gpgsign=false", "commit", "-m", "initial"})
    return repodir
end

function test_invalid_repositories_do_not_modify_parent(t)
    local gittool = import("lib.detect.find_tool")("git")
    if not gittool then return t:skip("git not found") end
    local parent = _make_repository(gittool)
    io.writefile(path.join(parent, "tracked.txt"), "uncommitted changes\n")
    io.writefile(path.join(parent, "staged.txt"), "staged changes\n")
    os.vrunv(gittool.program, {"-C", parent, "add", "staged.txt"})
    local status = os.iorunv(gittool.program, {"-C", parent, "status", "--porcelain"})
    local head = os.iorunv(gittool.program, {"-C", parent, "rev-parse", "HEAD"})
    -- Reproduce ancestor discovery inside a temporary user project, keeping the test runner safe.
    local oldir = os.cd(parent)
    try {
        function ()
            for _, name in ipairs({"missing", "empty", "broken", "gitfile", "incomplete"}) do
                local repodir = path.join(parent, ".xmake", "repositories", name)
                if name ~= "missing" then os.mkdir(repodir) end
                if name == "broken" then os.mkdir(path.join(repodir, ".git")) end
                if name == "gitfile" then io.writefile(path.join(repodir, ".git"), "invalid gitfile\n") end
                if name == "incomplete" then io.writefile(path.join(repodir, ".git", "HEAD"), "ref: refs/heads/master\n") end
                if name == "missing" or name == "empty" or name == "broken" then
                    t:are_equal(git.support.repository_gitdir(repodir), nil)
                end
                t:will_raise(function () git.remote.set_url("https://example.invalid/packages.git", {repodir = repodir}) end)
                t:will_raise(function () git.reset({repodir = repodir, hard = true}) end)
                t:will_raise(function () git.pull({repodir = repodir, force = true}) end)
                t:are_equal(git.remote.get_url({repodir = parent}), "https://example.invalid/project.git")
                t:are_equal(io.readfile(path.join(parent, "tracked.txt")), "uncommitted changes\n")
                -- Ignore the untracked test directories, but preserve the index and HEAD.
                local current = os.iorunv(gittool.program, {"-C", parent, "status", "--porcelain", "--untracked-files=no"})
                t:are_equal(current, status)
                t:are_equal(os.iorunv(gittool.program, {"-C", parent, "rev-parse", "HEAD"}), head)
            end
        end,
        finally {
            function () os.cd(oldir) end
        }
    }
end

function test_nested_repository_and_worktree(t)
    local gittool = import("lib.detect.find_tool")("git")
    if not gittool then return t:skip("git not found") end
    local parent = _make_repository(gittool)
    io.writefile(path.join(parent, "tracked.txt"), "parent changes\n")
    local child = path.join(parent, ".xmake", "repositories", "valid")
    git.clone(parent, {outputdir = child})
    t:require(git.support.repository_gitdir(child))
    git.remote.set_url(parent, {repodir = child})
    t:are_equal(git.remote.get_url({repodir = child}), parent)
    io.writefile(path.join(child, "tracked.txt"), "child changes\n")
    git.reset({repodir = child, hard = true})
    t:are_equal(io.readfile(path.join(child, "tracked.txt")), "committed\n")
    git.pull({repodir = child, branch = "master"})
    t:are_equal(io.readfile(path.join(parent, "tracked.txt")), "parent changes\n")
    local worktree = os.tmpfile() .. ".worktree"
    os.vrunv(gittool.program, {"-C", child, "worktree", "add", "-b", "test-worktree", worktree})
    t:require(os.isfile(path.join(worktree, ".git")))
    t:require(git.support.repository_gitdir(worktree))
    t:are_equal(git.remote.get_url({repodir = worktree}), parent)
    io.writefile(path.join(worktree, "tracked.txt"), "worktree changes\n")
    git.reset({repodir = worktree, hard = true})
    t:are_equal(io.readfile(path.join(worktree, "tracked.txt")), "committed\n")
    t:are_equal(io.readfile(path.join(parent, "tracked.txt")), "parent changes\n")
    local bare = os.tmpfile() .. ".bare"
    os.vrunv(gittool.program, {"clone", "--bare", child, bare})
    git.remote.set_url(parent, {repodir = bare})
    t:are_equal(git.remote.get_url({repodir = bare}), parent)
    t:will_raise(function () git.reset({repodir = bare, hard = true}) end)
end
