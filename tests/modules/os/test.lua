function test_cpdir(t)
    -- get mclock
    local tm = os.mclock()
    -- test cpdir
    os.mkdir("test1")
    t:require(os.exists("test1"))
    os.cp("test1","test2")
    t:require(os.exists("test2"))
    os.rmdir("test1")
    t:require_not(os.exists("test1"))
    io.writefile("test2/awd","awd")
    os.rmdir("test2")
    t:require_not(os.exists("test2"))
    -- assert mclock
    t:require(os.mclock() >= tm)
end

function test_rename(t)
    -- get mclock
    local tm = os.mclock()
    -- test rename
    os.mkdir("test1")
    t:require(os.exists("test1"))
    os.mv("test1","test2")
    t:require_not(os.exists("test1"))
    t:require(os.exists("test2"))
    os.rmdir("test2")
    t:require_not(os.exists("test2"))
    -- assert mclock
    t:require(os.mclock() >= tm)
end

function test_cp_mvdir_into_another_dir(t)
    -- get mclock
    local tm = os.mclock()
    -- test cp/mvdir into another dir
    os.mkdir("test1")
    os.mkdir("test2")
    t:require(os.exists("test1"))
    t:require(os.exists("test2"))
    os.cp("test1","test2")
    t:require(os.exists("test2/test1"))
    os.mv("test1","test2/test1")
    t:require_not(os.exists("test1"))
    t:require(os.exists("test2/test1/test1"))
    os.rmdir("test2")
    t:require_not(os.exists("test2"))
    -- assert mclock
    t:require(os.mclock() >= tm)
end

function test_setenv(t)
    -- get mclock
    local tm = os.mclock()
    -- test setenv
    os.setenv("__AWD","DWA")
    t:are_equal(os.getenv("__AWD"), "DWA")
    os.setenv("__AWD","DWA2")
    t:are_equal(os.getenv("__AWD"), "DWA2")
    -- assert mclock
    t:require(os.mclock() >= tm)
end

function test_argv(t)
    t:are_equal(os.argv(""), {})
    t:are_equal(os.argv("aa bb cc"), {"aa", "bb", "cc"})
    t:are_equal(os.argv("aa --bb=bbb -c"), {"aa", "--bb=bbb", "-c"})
    t:are_equal(os.argv("\"aa bb cc\" dd"), {"aa bb cc", "dd"})
    t:are_equal(os.argv("\"aa(bb)cc\" dd"), {"aa(bb)cc", "dd"})
    t:are_equal(os.argv("aa\\bb/cc dd"), {"aa\\bb/cc", "dd"})
    t:are_equal(os.argv("\"aa\\\\bb/cc dd\" ee"), {"aa\\bb/cc dd", "ee"})
    t:are_equal(os.argv("\"aa\\\\bb/cc (dd)\" ee"), {"aa\\bb/cc (dd)", "ee"})
    t:are_equal(os.argv("-D__prefix__=\\\"tbox\\\""), {"-D__prefix__=\"tbox\""})
end

function test_args(t)
    t:are_equal(os.args({}), "")
    t:are_equal(os.args({"aa", "bb", "cc"}), "aa bb cc")
    t:are_equal(os.args({"aa", "--bb=bbb", "-c"}), "aa --bb=bbb -c")
    t:are_equal(os.args({"aa bb cc", "dd"}), "\"aa bb cc\" dd")
    t:are_equal(os.args({"aa(bb)cc", "dd"}), "\"aa(bb)cc\" dd")
    t:are_equal(os.args({"aa\\bb/cc", "dd"}), "aa\\bb/cc dd")
    t:are_equal(os.args({"aa\\bb/cc dd", "ee"}), "\"aa\\\\bb/cc dd\" ee")
    t:are_equal(os.args({"aa\\bb/cc (dd)", "ee"}), "\"aa\\\\bb/cc (dd)\" ee")
    t:are_equal(os.args("-D__prefix__=\"tbox\""), "-D__prefix__=\\\"tbox\\\"")
    t:are_equal(os.args({"aa\\bb/cc", "dd"}, {escape = true}), "aa\\\\bb/cc dd")
end
