function main()
    print(os.cpuinfo())
    while true do
        print(os.time(), os.cpuinfo("usagerate"))
        os.sleep(1000)
    end
end
