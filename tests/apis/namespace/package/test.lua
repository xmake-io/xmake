function main()
    if is_host("bsd", "solaris") then
        return
    end
    os.exec("xmake -vD -y")
end
