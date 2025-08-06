function main(t)
    if not is_host("linux") then
        return
    end
    t:build()
end

