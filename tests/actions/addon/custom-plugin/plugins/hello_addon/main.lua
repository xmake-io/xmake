import("core.base.option")

function main()
    print("hello from custom-plugin: %s", option.get("name") or "world")
end
