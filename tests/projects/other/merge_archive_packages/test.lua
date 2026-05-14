function main(t)
    -- Solaris ar does not support merging archives with duplicate object file names
    if is_host("solaris") then
        return
    end
    t:build()
end
