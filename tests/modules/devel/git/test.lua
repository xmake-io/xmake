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