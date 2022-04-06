import("core.base.pipe")
import("core.base.bytes")

function main(name)
    local buff = bytes(8192)
    local pipefile = pipe.open(name or "test", 'r')
    if pipefile:connect() > 0 then
        print("%s: connected", pipefile)
        local count = 0
        local result = nil
        while count < 10000 do
            local read, data = pipefile:read(buff, 13, {block = true})
            if read > 0 then
                result = data
                count = count + 1
            else
                break
            end
        end
        print("%s: read: %d, count: %d", pipefile, result and result:size() or 0, count)
        result:dump()
    end
    pipefile:close()
end
