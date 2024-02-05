function main(t)
    if is_host("windows", "macosx", "linux") then
        os.exec("xmake -vD")
    end
end
