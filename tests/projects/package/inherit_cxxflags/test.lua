import("lib.detect.find_tool")

function main()
    local toolchains = {false}
    if is_subhost("windows") and find_tool("clang-cl") then
        table.insert(toolchains, "clang-cl")
    end
    for _, toolchain in ipairs(toolchains) do
        local config = {"f", "-c", "-y", "-m", "debug", "--ccache=n"}
        if toolchain then
            table.insert(config, "--toolchain=" .. toolchain)
        end
        os.execv(os.programfile(), config)
        os.execv(os.programfile(), {"build", "-r"})
        for _, name in ipairs({"consumer", "no_inherit", "override_consumer"}) do
            os.execv(os.programfile(), {"run", name})
        end
    end
end
