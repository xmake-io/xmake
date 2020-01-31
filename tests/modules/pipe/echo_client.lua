import("core.base.pipe")

function main(name)
    local pipefile = pipe.open(name or "test", 'w')
    local count = 0
    while count < 10000 do
        local write = pipefile:write("hello world..", {block = true})
        if write <= 0 then
            break
        end
        count = count + 1
    end
    print("%s: write ok, count: %d!", pipefile, count)
    pipefile:close()
end
