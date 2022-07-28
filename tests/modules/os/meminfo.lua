function main()
    while true do
        print("%d%%", math.floor(os.meminfo("usagerate") * 100))
        os.sleep(1000)
    end
end
