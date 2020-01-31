import("core.base.pipe")

function main()
    local rpipe, wpipe = pipe.openpair(4096)
    wpipe:write("hello xmake!", {block = true})
    local read, data = rpipe:read(13)
    if read > 0 and data then
        data:dump()
    end
    rpipe:close()
    wpipe:close()
end
