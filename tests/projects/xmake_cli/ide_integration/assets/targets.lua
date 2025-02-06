-- imports
import("core.project.config")
import("core.project.project")
import("core.base.json")

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
    local localjson =  json.encode(names)

    print("__begin__")
    print(localjson)
    print("__end__")
end
