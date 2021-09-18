function main(t)
    -- TODO
    if xmake.luajit() then
        t:build()
    end
end
