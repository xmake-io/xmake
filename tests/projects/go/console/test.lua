-- main entry
function main(t)

    -- build project
    if os.host() == "macosx" then
        t:build()
    end
end
