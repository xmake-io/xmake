function main()
    print(os.cpuinfo())
    while true do
        print("total: %d%%", math.floor(os.cpuinfo("usagerate") * 100))
        os.sleep(1000)
    end
end
