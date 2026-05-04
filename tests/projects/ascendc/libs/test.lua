function main(t)
    if not is_host("linux") then
        return t:skip("wrong host platform")
    end
    if not os.getenv("ASCEND_HOME_PATH") then
        return t:skip("ASCEND_HOME_PATH not set")
    end
    t:build()
end
