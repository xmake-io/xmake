function main(t)
    if is_host("macosx") and os.arch() == "arm64" then
        return
    end
    t:build()
end
