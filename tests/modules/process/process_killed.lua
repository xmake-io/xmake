import("core.base.process")
import("core.base.scheduler")

function main(cmd)
    for i = 1, 10 do
        scheduler.co_start(function ()
            -- @note we need test xx.bat cmd on windows
            local proc = process.open(cmd or "xmake l os.sleep 60000")
            print("%s: wait ..", proc)
            -- we need terminate all unclosed processes automatically after parent process is exited after do ctrl-c
            proc:wait(-1)
            print("%s: wait ok", proc)
            proc:close()
        end)
    end
end
