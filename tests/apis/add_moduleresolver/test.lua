function main(test)
    -- The generic test:build() helper shells out to `xmake` by name. That fails
    -- when testing from a local build tree where xmake is available as the
    -- current program but is not installed system-wide. Invoke the currently
    -- running executable directly instead.
    local xmake = os.programfile()

    os.execv(xmake, {"f", "-c", "-D", "-y"})
end