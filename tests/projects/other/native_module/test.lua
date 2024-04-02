function main(t)
    if not xmake.luajit() then
        t:build()
    end
end
