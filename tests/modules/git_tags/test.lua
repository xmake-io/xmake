import("devel.git")
import("lib.detect.find_tool")

function test_annotated_tags(t)
    local gittool = find_tool("git")
    if not gittool then
        return t:skip("git not found")
    end
    local repodir = os.tmpfile() .. ".git"
    os.mkdir(repodir)
    try
    {
        function ()
            os.vrunv(gittool.program, {"init", "-q"}, {curdir = repodir})
            io.writefile(path.join(repodir, "README"), "git tag fixture\n")
            os.vrunv(gittool.program, {"add", "README"}, {curdir = repodir})
            local identity = {"-c", "user.name=xmake", "-c", "user.email=xmake@xmake.io",
                              "-c", "commit.gpgsign=false", "-c", "tag.gpgsign=false"}
            os.vrunv(gittool.program, table.join(identity, {"commit", "-q", "-m", "fixture"}), {curdir = repodir})
            os.vrunv(gittool.program, {"tag", "lightweight"}, {curdir = repodir})

            -- Existing lightweight tag and branch queries must keep working.
            t:are_equal(git.tags(repodir), {"lightweight"})
            local branches = git.branches(repodir)
            t:are_equal(#branches, 1)
            local tags, refbranches = git.refs(repodir)
            t:are_equal(tags, {"lightweight"})
            t:are_equal(refbranches, branches)

            os.vrunv(gittool.program, table.join(identity, {"tag", "-a", "release/v1", "-m", "annotated fixture"}), {curdir = repodir})
            tags, refbranches = git.refs(repodir)
            t:are_equal(tags, {"lightweight", "release/v1"})
            t:are_equal(refbranches, branches)
            print("lightweight tag, branch and refs controls passed")

            -- A peeled annotated tag is not a second tag named release/v1^{}.
            local listedtags = git.tags(repodir)
            print("git.tags: %s", table.concat(listedtags, ", "))
            t:are_equal(listedtags, tags)
            t:are_equal(git.ls_remote("tags", repodir), tags)
        end,
        finally
        {
            function (ok, errors)
                os.tryrm(repodir)
                if not ok then
                    raise(errors)
                end
            end
        }
    }
end
