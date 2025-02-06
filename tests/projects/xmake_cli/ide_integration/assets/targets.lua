import("core.project.config")
import("core.project.project")
import("core.base.json")
import("lib.lni")

function main ()
    config.load()

    local names = {}
    for name, _ in pairs((project.targets())) do
        table.insert(names, name)
    end
    table.sort(names)
    if json.mark_as_array then
        json.mark_as_array(names)
    end
    lni.result = json.encode(names)
end
