function record(phase, event, package)
    local file = io.open(path.join(os.projectdir(), "events.log"), "a")
    file:print("%s %s %s", phase, event, package:name())
    file:close()
end
