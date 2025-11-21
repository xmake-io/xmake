import("async.runjobs")

function main()
    printf("testing .. ")
    runjobs("test", function ()
        os.sleep(10000)
    end, {waiting_indicator = true})
    print("ok")
end

