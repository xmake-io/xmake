import("core.base.option")
import("@self.greeting")

function main()
    print(greeting(option.get("name")))
end
