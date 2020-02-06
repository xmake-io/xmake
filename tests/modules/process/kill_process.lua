import("core.base.process")
import("core.base.scheduler")

function main(program, ...)
    for i = 1, 10 do
        scheduler.co_start(function ()
            -- we need terminate all unclosed processes automatically after parent process is exited
            process.open("xmake l os.sleep 60000")
        end)
    end
    -- check processes status after exiting
    -- ps aux | grep sleep
end
