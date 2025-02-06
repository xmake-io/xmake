import("core.project.config")
import("core.project.project")

function main (targetname)
    config.load()
    if not os.isfile(os.projectfile()) then
        return
    end

    local target = nil
    if targetname then
        target = project.target(targetname)
    end
    if not target then
        for _, t in pairs(project.targets()) do
            local default = t:get("default")
            if (default == nil or default == true) and t:get("kind") == "binary" then
                target = t
                break
            end
        end
    end
    
    print("__begin__")

    if target then
        local targetfile = target:targetfile()
        if not path.is_absolute(targetfile) then
            targetfile = path.absolute(targetfile, os.projectdir())
        end
        print(targetfile)
    end

    print("__end__")
end
