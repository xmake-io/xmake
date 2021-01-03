function main(t)
    if is_plat(os.subhost()) and is_arch(os.subarch()) then
        t:build()
    end
end
