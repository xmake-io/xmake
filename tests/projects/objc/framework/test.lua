function main(t)
    if is_host("macosx") then
        t:build({iphoneos = true})
    else
        return t:skip("wrong host platform")
    end
end
