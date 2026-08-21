function main(t)
    if os.subarch():startswith("x") or os.subarch() == "i386" then
        t:build()
    end
end
