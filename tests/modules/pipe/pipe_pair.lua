import("core.base.pipe")
import("core.base.bytes")

function main()
    local buff = bytes(8192)
    local rpipe, wpipe = pipe.openpair()
    wpipe:write("hello xmake!", {block = true})
    local read, data = rpipe:read(buff, 13)
    if read > 0 and data then
        data:dump()
    end
    rpipe:close()
    wpipe:close()
end
