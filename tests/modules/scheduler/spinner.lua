import("private.async.runjobs")

function main()
    printf("testing .. ")
    runjobs("test", function ()
        os.sleep(10000)
    end, {progress = true})
    print("ok")
end

