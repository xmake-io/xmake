function main(t)
    if is_plat(os.subhost()) then
        t:build()
    end
end
