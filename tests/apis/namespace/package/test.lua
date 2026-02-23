function main()
    if is_host("bsd", "solaris", "haiku") then
        return
    end
    os.exec("xmake -vD -y")
end
