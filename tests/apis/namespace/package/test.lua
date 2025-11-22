function main()
    if is_host("bsd") then
        return
    end
    os.exec("xmake -vD -y")
end
