import("core.base.signal")

function main()
    signal.register(signal.SIGINT, function (signo)
        print("signal.SIGINT(%d)", signo)
    end)
    io.read()
end
