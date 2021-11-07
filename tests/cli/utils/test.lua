function test_version(t)
    local output = os.iorunv("xmake", {"--version"})
    local vstr = output:match("xmake v(.-),")
print(11, xmake.version())
    t:are_equal(vstr, tostring(xmake.version()))
end

function test_help(t)
    import("core.base.task")
    for _, taskname in ipairs(task.names()) do
        os.runv("xmake", {taskname, "--help"})
    end
end
