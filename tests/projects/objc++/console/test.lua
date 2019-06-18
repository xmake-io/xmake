-- main entry
function main(t)

    -- build project
    if os.host() == "macosx" then
        t:build({iphoneos = true})
    else
        return t:skip("wrong host platform")
    end
end
