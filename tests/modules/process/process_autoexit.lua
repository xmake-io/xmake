import("core.base.process")
import("core.base.scheduler")

function main(cmd)
    for i = 1, 10 do
        scheduler.co_start(function ()
            process.open(cmd or "xmake l os.sleep 60000")
            --process.openv("xmake", {"l", "os.sleep", "60000"}, {detach = true}):close()
        end)
    end
    -- check processes status after exiting
    -- we need terminate all unclosed processes automatically after parent process is exited
    -- ps aux | grep sleep
end
