target("test")
    set_kind("phony")
    on_run(function (target)
        import("core.base.option")
        local xmake = path.unix(os.programfile())
        local xmake_dir = os.getenv("XMAKE_PROGRAM_DIR")
        print("XMAKE_PROGRAM_DIR: " .. (xmake_dir or "nil"))
        print("xmake binary: " .. xmake)
        
        if xmake_dir then
            xmake_dir = path.unix(xmake_dir)
            if os.host() == "windows" then
                xmake_dir = xmake_dir:gsub("/", "\\")
            end
            os.setenv("XMAKE_PROGRAM_DIR", xmake_dir)
        end

        -- New Helper: Probe for feature working (handles Windows/pwsh fallback)
        local function check_feature()
            print("Checking feature: --from-stdin ...")
            local shell = os.shell()
            
            -- 1. Try detected shell if compatible
            if shell == "pwsh" or shell == "powershell" then
                 local pwsh_probe = string.format("Write-Output \"print('probe_ok')\" | & '%s' lua --from-stdin", xmake)
                 local ok, out, _ = os.iorun_in_shell(shell, pwsh_probe)
                 if ok and out and out:find("probe_ok") then return true end
            elseif shell == "cmd" then
                 local win_xmake = xmake:gsub("/", "\\")
                 local cmd_probe = string.format("echo print\"probe_ok\" | \"%s\" lua --from-stdin", win_xmake)
                 local ok, out, _ = os.iorun_in_shell("cmd", cmd_probe)
                 if ok and out and out:find("probe_ok") then return true end
            end

            -- 2. Try generic sh (preferred if available validation default)
            local probe_cmd = string.format("echo 'print(\"probe_ok\")' | %s lua --from-stdin", xmake)
            local ok, out, _ = os.iorun_in_shell("sh", probe_cmd)
            if ok and out and out:find("probe_ok") then return true end
            
            -- 3. Fallback: On Windows, try pwsh if sh failed
            if os.host() == "windows" and shell ~= "pwsh" and shell ~= "powershell" and shell ~= "cmd" then
                 local pwsh_probe = string.format("Write-Output \"print('probe_ok')\" | & '%s' lua --from-stdin", xmake)
                 local ok, out, _ = os.iorun_in_shell("pwsh", pwsh_probe)
                 if ok and out and out:find("probe_ok") then return true end
            end
            return false
        end
 
        -- check if feature is present
        if check_feature() then
            print("Feature presence check: PASS")
        else
            local ok, out, err = os.iorun_in_shell("sh", string.format("%s lua --help", xmake))
            if out and out:find("--from-stdin", 1, true) then
                print("Feature presence check: PASS (via help text)")
            else
                print("Feature presence check: FAIL")
                print("Help output (snippet): " .. (out and out:sub(1,100) or "nil"))
            end
        end
 
        -- test 1: pipe a few lines of lua code from echo (multiline)
        local pipe_cmd = string.format("(echo 'print(\"hello\")'; echo 'print(\"from pipe\")') | '%s' lua --from-stdin", xmake)
        print("running: " .. pipe_cmd)
        local ok, out, err = os.iorun_in_shell("sh", pipe_cmd)
        print("STDOUT 1:\n" .. (out or ""))
        print("STDERR 1:\n" .. (err or ""))
        assert(ok, "test 1 failed: command returned error")
        if out then
            assert(out:find("hello") and out:find("from pipe"), "test 1 failed: output mismatch")
        end
 
        -- test 2: redirect from a .lua file (multiline)
        -- FIX: Use cat and merge stderr (2>&1) to ensure we capture output robustly without hanging on Win
        local scriptfile = path.join(os.curdir(), "test.lua")
        io.writefile(scriptfile, 'print("hello")\nprint("from file")\n')
 
        local cat_cmd = string.format("cat '%s' | '%s' lua --from-stdin 2>&1", path.unix(scriptfile), xmake)
        print("running: " .. cat_cmd)
        ok, out, err = os.iorun_in_shell("sh", cat_cmd)
        print("STDOUT 2:\n" .. (out or ""))
        print("STDERR 2:\n" .. (err or ""))
 
        assert(ok, "test 2 failed: command returned error")
        if out then
            assert(out:find("hello") and out:find("from file"), "test 2 failed: output mismatch")
        end
        os.rm(scriptfile)
 
        -- test 3: verify traceback on error via pipe (multiline)
        local error_pipe_cmd = string.format("(echo 'print(\"ok step\")'; echo 'raise(\"error_pipe\")') | '%s' lua --from-stdin", xmake)
        print("running: " .. error_pipe_cmd)
        ok, out, err = os.iorun_in_shell("sh", error_pipe_cmd)
        print("STDOUT 3:\n" .. (out or ""))
        print("STDERR 3:\n" .. (err or ""))
        assert(not ok, "test 3 failed: command should have returned error") 
        if out then assert(out:find("ok step"), "test 3 failed: missing ok step output") end
        assert((err and err:find("error_pipe")) or (out and out:find("error_pipe")), "test 3 failed: missing error message")
 
        -- test 4: verify traceback on error via file (multiline)
        local errorfile = path.join(os.curdir(), "error.lua")
        io.writefile(errorfile, 'print("ok step")\nraise("error_file")\n')
 
        -- FIX: Use cat and merge stderr (2>&1)
        local error_file_cmd = string.format("cat '%s' | '%s' lua --from-stdin 2>&1", path.unix(errorfile), xmake)
        print("running: " .. error_file_cmd)
        ok, out, err = os.iorun_in_shell("sh", error_file_cmd)
        print("STDOUT 4:\n" .. (out or ""))
        print("STDERR 4:\n" .. (err or ""))
 
        assert(not ok, "test 4 failed: command should have returned error")
        -- Check out (merged) or err just in case
        if out then assert(out:find("ok step"), "test 4 failed: missing ok step output") end
        assert((err and err:find("error_file")) or (out and out:find("error_file")), "test 4 failed: missing error message")
        os.rm(errorfile)
 
        -- pwsh tests
        if os.execv("pwsh", {"-v"}) == 0 then
            print("pwsh detected, running pwsh tests...")
 
            -- test 5: pwsh pipe success (multiline)
            local pwsh_pipe_cmd = string.format("Write-Output \"print(`\"hello`\")`nprint(`\"from pwsh pipe`\")\" | & '%s' lua --from-stdin", xmake)
            print("running pwsh: " .. pwsh_pipe_cmd)
            ok, out, err = os.iorun_in_shell("pwsh", pwsh_pipe_cmd)
            print("STDOUT 5:\n" .. (out or ""))
            print("STDERR 5:\n" .. (err or ""))
            assert(ok, "test 5 failed: command returned error")
            if out then
                assert(out:find("hello") and out:find("from pwsh pipe"), "test 5 failed: output mismatch")
            end
 
            -- test 6: pwsh file redirect success (multiline)
            local scriptfile = path.join(os.curdir(), "test_pwsh.lua")
            io.writefile(scriptfile, 'print("hello")\nprint("from pwsh file")\n')
            local pwsh_redirect_cmd = string.format("Get-Content '%s' | & '%s' lua --from-stdin", scriptfile, xmake)
            print("running pwsh: " .. pwsh_redirect_cmd)
            ok, out, err = os.iorun_in_shell("pwsh", pwsh_redirect_cmd)
            print("STDOUT 6:\n" .. (out or ""))
            print("STDERR 6:\n" .. (err or ""))
            assert(ok, "test 6 failed: command returned error")
            if out then
                assert(out:find("hello") and out:find("from pwsh file"), "test 6 failed: output mismatch")
            end
            os.rm(scriptfile)
 
            -- test 7: pwsh pipe error (multiline)
            local pwsh_error_pipe_cmd = string.format("Write-Output \"print(`\"ok step`\")`nraise(`\"error_pwsh_pipe`\")\" | & '%s' lua --from-stdin", xmake)
            print("running pwsh: " .. pwsh_error_pipe_cmd)
            ok, out, err = os.iorun_in_shell("pwsh", pwsh_error_pipe_cmd)
            print("STDOUT 7:\n" .. (out or ""))
            print("STDERR 7:\n" .. (err or ""))
            assert(not ok, "test 7 failed: command should have returned error") 
            if out then assert(out:find("ok step"), "test 7 failed: missing ok step output") end
            assert((err and err:find("error_pwsh_pipe")) or (out and out:find("error_pwsh_pipe")), "test 7 failed: missing error message")
 
            -- test 8: pwsh file redirect error (multiline)
            local errorfile = path.join(os.curdir(), "error_pwsh.lua")
            io.writefile(errorfile, 'print("ok step")\nraise("error_pwsh_file")\n')
            local pwsh_error_file_cmd = string.format("Get-Content '%s' | & '%s' lua --from-stdin", errorfile, xmake)
            print("running pwsh: " .. pwsh_error_file_cmd)
            ok, out, err = os.iorun_in_shell("pwsh", pwsh_error_file_cmd)
            print("STDOUT 8:\n" .. (out or ""))
            print("STDERR 8:\n" .. (err or ""))
            assert(not ok, "test 8 failed: command should have returned error") 
            if out then assert(out:find("ok step"), "test 8 failed: missing ok step output") end
            assert((err and err:find("error_pwsh_file")) or (out and out:find("error_pwsh_file")), "test 8 failed: missing error message")
            os.rm(errorfile)
        else
            print("pwsh not found, skipping pwsh tests")
        end
 
        -- cmd tests
        if os.host() == "windows" then
            print("windows detected, running cmd.exe tests...")
            local win_xmake = xmake:gsub("/", "\\")
 
            -- test 9: cmd pipe success (multiline)
            local cmd_pipe_cmd = string.format("(echo print\"hello\" && echo print\"from cmd pipe\") | \"%s\" lua --from-stdin", win_xmake)
            print("running cmd: " .. cmd_pipe_cmd)
            ok, out, err = os.iorun_in_shell("cmd", cmd_pipe_cmd)
            print("STDOUT 9:\n" .. (out or ""))
            print("STDERR 9:\n" .. (err or ""))
            assert(ok, "test 9 failed: command returned error")
            if out then assert(out:find("hello") and out:find("from cmd pipe"), "test 9 failed: output mismatch") end
 
            -- test 10: cmd file pipe success (multiline)
            local scriptfile = path.join(os.curdir(), "test_cmd.lua")
            local win_scriptfile = scriptfile:gsub("/", "\\")
            -- FIX: Add newline for robust 'type' piping
            io.writefile(scriptfile, 'print("hello")\nprint("from cmd file")\n')
 
            local cmd_file_cmd = string.format("type \"%s\" | \"%s\" lua --from-stdin", win_scriptfile, win_xmake)
            print("running cmd: " .. cmd_file_cmd)
            ok, out, err = os.iorun_in_shell("cmd", cmd_file_cmd)
            print("STDOUT 10:\n" .. (out or ""))
            print("STDERR 10:\n" .. (err or ""))
            assert(ok, "test 10 failed: command returned error")
            if out then assert(out:find("hello") and out:find("from cmd file"), "test 10 failed: output mismatch") end
            os.rm(scriptfile)
 
            -- test 11: cmd pipe error (multiline)
            local cmd_err_pipe_cmd = string.format("(echo print\"ok step\" && echo raise\"error_cmd_pipe\") | \"%s\" lua --from-stdin", win_xmake)
            print("running cmd: " .. cmd_err_pipe_cmd)
            ok, out, err = os.iorun_in_shell("cmd", cmd_err_pipe_cmd)
            print("STDOUT 11:\n" .. (out or ""))
            print("STDERR 11:\n" .. (err or ""))
            assert(not ok, "test 11 failed: command should have returned error")
            if out then assert(out:find("ok step"), "test 11 failed: missing ok step output") end
            assert((err and err:find("error_cmd_pipe")) or (out and out:find("error_cmd_pipe")), "test 11 failed: missing error message")
 
             -- test 12: cmd file pipe error (multiline)
            local errorfile = path.join(os.curdir(), "error_cmd.lua")
            local win_errorfile = errorfile:gsub("/", "\\")
            io.writefile(errorfile, 'print("ok step")\nraise("error_cmd_file")\n')
 
            local cmd_err_file_cmd = string.format("type \"%s\" | \"%s\" lua --from-stdin", win_errorfile, win_xmake)
            print("running cmd: " .. cmd_err_file_cmd)
            ok, out, err = os.iorun_in_shell("cmd", cmd_err_file_cmd)
            print("STDOUT 12:\n" .. (out or ""))
            print("STDERR 12:\n" .. (err or ""))
            assert(not ok, "test 12 failed: command should have returned error") 
            if out then assert(out:find("ok step"), "test 12 failed: missing ok step output") end
            assert((err and err:find("error_cmd_file")) or (out and out:find("error_cmd_file")), "test 12 failed: missing error message")
            os.rm(errorfile)
        end
    end)
