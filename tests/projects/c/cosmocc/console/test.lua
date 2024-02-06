function main(t)
    if is_subhost("msys", "cygwin") then
        os.exec("xmake f -y -p windows -vD")
        os.exec("xmake -vD")
    elseif is_host("macosx", "linux") then
        os.exec("xmake -y -vD")
    end
end
