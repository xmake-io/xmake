import("devel.git")


function test_asgiturl()
    assert(git.asgiturl("http://github.com/a/b") == "https://github.com/a/b.git")
    assert(git.asgiturl("http://github.com/a/b/") == "https://github.com/a/b.git")
    assert(git.asgiturl("HTTP://github.com//a/b/") == "https://github.com/a/b.git")
    assert(git.asgiturl("http://github.com//a/b/s") == nil)
    assert(git.asgiturl("https://github.com/a/b") == "https://github.com/a/b.git")
    assert(git.asgiturl("https://github.com/a/b.git") == "https://github.com/a/b.git")
    assert(git.asgiturl("HTTPS://GITHUB.com/a/b.git.git") == "https://github.com/a/b.git.git")

    assert(git.asgiturl("github:a/b") == "https://github.com/a/b.git")
    assert(git.asgiturl("github:a/b.git") == "https://github.com/a/b.git.git")
    assert(git.asgiturl("GitHub://a/b/") == "https://github.com/a/b.git")
    assert(git.asgiturl("github:a/b/c") == nil)
end

function main()
    test_asgiturl()
end