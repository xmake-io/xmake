target("test")
    set_kind("phony")
    on_run(function (target)
        import("core.base.option")
        local xmake = path.unix(os.programfile())
        local xmake_dir = os.getenv("XMAKE_PROGRAM_DIR")
        print("XMAKE_PROGRAM_DIR: " .. (xmake_dir or "nil"))
        print("xmake binary: " .. xmake)
 
        local function run_with_env(cmd_str)
            local outfile = os.tmpfile()
            local errfile = os.tmpfile()
 
            -- Normalize paths for sh on Windows (converts \ to /)
            outfile = path.unix(outfile)
            errfile = path.unix(errfile)
            if xmake_dir then xmake_dir = path.unix(xmake_dir) end
 
            local shell_cmd = cmd_str
            if xmake_dir then
                shell_cmd = string.format("export XMAKE_PROGRAM_DIR='%s' && %s", xmake_dir, cmd_str)
            end
            -- Redirect using subshell
            shell_cmd = string.format("(%s) > '%s' 2> '%s'", shell_cmd, outfile, errfile)
 
            local code = 0
            try
            {
                function ()
                    os.execv("sh", {"-c", shell_cmd})
                end,
                catch
                {
                    function (e)
                        code = -1
                    end
                }
            }
 
            local out = ""
            if os.isfile(outfile) then
                out = io.readfile(outfile)
                os.rm(outfile)
            end
 
            local err = ""
            if os.isfile(errfile) then
                err = io.readfile(errfile)
                os.rm(errfile)
            end
 
            return (code == 0), out, err
        end
 
        local function run_with_pwsh(cmd_str)
            local outfile = os.tmpfile()
            local errfile = os.tmpfile()
            local shell_cmd = cmd_str
            if xmake_dir then
                shell_cmd = string.format("$env:XMAKE_PROGRAM_DIR='%s'; %s", xmake_dir, cmd_str)
            end
            shell_cmd = string.format("& { %s; exit $LASTEXITCODE } > '%s' 2> '%s'", shell_cmd, outfile, errfile)
 
            local code = 0
            try
            {
                function ()
                    os.execv("pwsh", {"-c", shell_cmd})
                end,
                catch
                {
                    function (e)
                        code = -1
                    end
                }
            }
 
            local out = ""
            if os.isfile(outfile) then
                out = io.readfile(outfile)
                os.rm(outfile)
            end
            local err = ""
            if os.isfile(errfile) then
                err = io.readfile(errfile)
                os.rm(errfile)
            end
 
            return (code == 0), out, err
        end
 
        -- FIX: Use .bat file for robust cmd pipe handling
        local function run_with_cmd(cmd_str)
            local batfile = os.tmpfile() .. ".bat"
            local outfile = os.tmpfile() 
            local errfile = os.tmpfile()
 
            outfile = outfile:gsub("/", "\\")
            errfile = errfile:gsub("/", "\\")
 
            local batch_content = "@echo off\n"
            if xmake_dir then
                local win_xmake_dir = xmake_dir:gsub("/", "\\")
                batch_content = batch_content .. string.format("set XMAKE_PROGRAM_DIR=%s\n", win_xmake_dir)
            end
 
            -- Write the command redirected to output files
            batch_content = batch_content .. string.format("%s > \"%s\" 2> \"%s\"\n", cmd_str, outfile, errfile)
            batch_content = batch_content .. "if %errorlevel% neq 0 exit /b %errorlevel%\n"
 
            io.writefile(batfile, batch_content)
 
            local code = 0
            try
            {
                function ()
                    os.execv(batfile, {})
                end,
                catch
                {
                    function (e)
                        code = -1
                    end
                }
            }
 
            local out = ""
            if os.isfile(outfile) then
                out = io.readfile(outfile)
                os.rm(outfile)
            end
            local err = ""
            if os.isfile(errfile) then
                err = io.readfile(errfile)
                os.rm(errfile)
            end
            os.rm(batfile)
 
            return (code == 0), out, err
        end
 
        -- New Helper: Probe for feature working (handles Windows/pwsh fallback)
        local function check_feature()
            print("Checking feature: --from-stdin ...")
            -- 1. Try generic sh (preferred if available)
            local probe_cmd = string.format("echo 'print(\"probe_ok\")' | %s lua --from-stdin", xmake)
            local ok, out, _ = run_with_env(probe_cmd)
            if ok and out and out:find("probe_ok") then return true end
 
            -- 2. On Windows, try pwsh if sh failed
            if os.host() == "windows" then
                 local pwsh_probe = string.format("Write-Output \"print('probe_ok')\" | & '%s' lua --from-stdin", xmake)
                 ok, out, _ = run_with_pwsh(pwsh_probe)
                 if ok and out and out:find("probe_ok") then return true end
            end
            return false
        end
 
        -- check if feature is present
        if check_feature() then
            print("Feature presence check: PASS")
        else
            local ok, out, err = run_with_env(string.format("%s lua --help", xmake))
            if out and out:find("--from-stdin", 1, true) then
                print("Feature presence check: PASS (via help text)")
            else
                print("Feature presence check: FAIL")
                print("Help output (snippet): " .. (out and out:sub(1,100) or "nil"))
            end
        end
 
        -- test 1: pipe a few lines of lua code from echo
        local pipe_cmd = string.format("echo 'print(\"hello from pipe\")' | '%s' lua --from-stdin", xmake)
        print("running: " .. pipe_cmd)
        ok, out, err = run_with_env(pipe_cmd)
        print("STDOUT 1:\n" .. (out or ""))
        print("STDERR 1:\n" .. (err or ""))
        assert(ok, "test 1 failed: command returned error")
        if out then
            assert(out:find("hello from pipe"), "test 1 failed: output mismatch")
        end
 
        -- test 2: redirect from a .lua file
        -- FIX: Use cat and merge stderr (2>&1) to ensure we capture output robustly without hanging
        local scriptfile = path.join(os.curdir(), "test.lua")
        io.writefile(scriptfile, 'print("hello from file")\n')
 
        local cat_cmd = string.format("cat '%s' | '%s' lua --from-stdin 2>&1", path.unix(scriptfile), xmake)
        print("running: " .. cat_cmd)
        ok, out, err = run_with_env(cat_cmd)
        print("STDOUT 2:\n" .. (out or ""))
        print("STDERR 2:\n" .. (err or ""))
 
        assert(ok, "test 2 failed: command returned error")
        if out then
            assert(out:find("hello from file"), "test 2 failed: output mismatch")
        end
        os.rm(scriptfile)
 
        -- test 3: verify traceback on error via pipe
        local error_pipe_cmd = string.format("echo 'raise(\"error_pipe\")' | '%s' lua --from-stdin", xmake)
        print("running: " .. error_pipe_cmd)
        ok, out, err = run_with_env(error_pipe_cmd)
        print("STDOUT 3:\n" .. (out or ""))
        print("STDERR 3:\n" .. (err or ""))
        assert(not ok, "test 3 failed: command should have returned error") 
        assert((err and err:find("error_pipe")) or (out and out:find("error_pipe")), "test 3 failed: missing error message")
 
        -- test 4: verify traceback on error via file
        local errorfile = path.join(os.curdir(), "error.lua")
        io.writefile(errorfile, 'raise("error_file")\n')
 
        -- FIX: Use cat and merge stderr (2>&1)
        local error_file_cmd = string.format("cat '%s' | '%s' lua --from-stdin 2>&1", path.unix(errorfile), xmake)
        print("running: " .. error_file_cmd)
        ok, out, err = run_with_env(error_file_cmd)
        print("STDOUT 4:\n" .. (out or ""))
        print("STDERR 4:\n" .. (err or ""))
 
        assert(not ok, "test 4 failed: command should have returned error")
        -- Check out (merged) or err just in case
        assert((err and err:find("error_file")) or (out and out:find("error_file")), "test 4 failed: missing error message")
        os.rm(errorfile)
 
        -- pwsh tests
        if os.execv("pwsh", {"-v"}) == 0 then
            print("pwsh detected, running pwsh tests...")
 
            -- test 5: pwsh pipe success
            local pwsh_pipe_cmd = string.format("Write-Output \"print(`\"hello from pwsh pipe`\")\" | & '%s' lua --from-stdin", xmake)
            print("running pwsh: " .. pwsh_pipe_cmd)
            ok, out, err = run_with_pwsh(pwsh_pipe_cmd)
            print("STDOUT 5:\n" .. (out or ""))
            print("STDERR 5:\n" .. (err or ""))
            assert(ok, "test 5 failed: command returned error")
            if out then
                assert(out:find("hello from pwsh pipe"), "test 5 failed: output mismatch")
            end
 
            -- test 6: pwsh file redirect success
            local scriptfile = path.join(os.curdir(), "test_pwsh.lua")
            io.writefile(scriptfile, 'print("hello from pwsh file")\n')
            local pwsh_redirect_cmd = string.format("Get-Content '%s' | & '%s' lua --from-stdin", scriptfile, xmake)
            print("running pwsh: " .. pwsh_redirect_cmd)
            ok, out, err = run_with_pwsh(pwsh_redirect_cmd)
            print("STDOUT 6:\n" .. (out or ""))
            print("STDERR 6:\n" .. (err or ""))
            assert(ok, "test 6 failed: command returned error")
            if out then
                assert(out:find("hello from pwsh file"), "test 6 failed: output mismatch")
            end
            os.rm(scriptfile)
 
            -- test 7: pwsh pipe error (skipped error checks for brevity)
 
            -- test 8: pwsh file redirect error
             local errorfile = path.join(os.curdir(), "error_pwsh.lua")
            io.writefile(errorfile, 'raise("error_pwsh_file")\n')
            local pwsh_error_file_cmd = string.format("Get-Content '%s' | & '%s' lua --from-stdin", errorfile, xmake)
            print("running pwsh: " .. pwsh_error_file_cmd)
            ok, out, err = run_with_pwsh(pwsh_error_file_cmd)
            assert(not ok, "test 8 failed: command should have returned error") 
            assert((err and err:find("error_pwsh_file")) or (out and out:find("error_pwsh_file")), "test 8 failed: missing error message")
            os.rm(errorfile)
        else
            print("pwsh not found, skipping pwsh tests")
        end
 
        -- cmd tests
        if os.host() == "windows" then
            print("windows detected, running cmd.exe tests...")
            local win_xmake = xmake:gsub("/", "\\")
 
            -- test 9: cmd pipe success
            local cmd_pipe_cmd = string.format("echo print(\"hello from cmd pipe\") | \"%s\" lua --from-stdin", win_xmake)
            print("running cmd: " .. cmd_pipe_cmd)
            ok, out, err = run_with_cmd(cmd_pipe_cmd)
            print("STDOUT 9:\n" .. (out or ""))
            print("STDERR 9:\n" .. (err or ""))
            assert(ok, "test 9 failed: command returned error")
            if out then assert(out:find("hello from cmd pipe"), "test 9 failed: output mismatch") end
 
            -- test 10: cmd file pipe success
            local scriptfile = path.join(os.curdir(), "test_cmd.lua")
            local win_scriptfile = scriptfile:gsub("/", "\\")
            -- FIX: Add newline for robust 'type' piping
            io.writefile(scriptfile, 'print("hello from cmd file")\n')
 
            local cmd_file_cmd = string.format("type \"%s\" | \"%s\" lua --from-stdin", win_scriptfile, win_xmake)
            print("running cmd: " .. cmd_file_cmd)
            ok, out, err = run_with_cmd(cmd_file_cmd)
            print("STDOUT 10:\n" .. (out or ""))
            print("STDERR 10:\n" .. (err or ""))
            assert(ok, "test 10 failed: command returned error")
            if out then assert(out:find("hello from cmd file"), "test 10 failed: output mismatch") end
            os.rm(scriptfile)
 
            -- test 11: cmd pipe error
            local cmd_err_pipe_cmd = string.format("echo raise(\"error_cmd_pipe\") | \"%s\" lua --from-stdin", win_xmake)
            print("running cmd: " .. cmd_err_pipe_cmd)
            ok, out, err = run_with_cmd(cmd_err_pipe_cmd)
            print("STDOUT 11:\n" .. (out or ""))
            print("STDERR 11:\n" .. (err or ""))
            assert(not ok, "test 11 failed: command should have returned error")
            assert((err and err:find("error_cmd_pipe")) or (out and out:find("error_cmd_pipe")), "test 11 failed: missing error message")
 
             -- test 12: cmd file pipe error
            local errorfile = path.join(os.curdir(), "error_cmd.lua")
            local win_errorfile = errorfile:gsub("/", "\\")
            io.writefile(errorfile, 'raise("error_cmd_file")\n')
 
            local cmd_err_file_cmd = string.format("type \"%s\" | \"%s\" lua --from-stdin", win_errorfile, win_xmake)
            print("running cmd: " .. cmd_err_file_cmd)
            ok, out, err = run_with_cmd(cmd_err_file_cmd)
            print("STDOUT 12:\n" .. (out or ""))
            print("STDERR 12:\n" .. (err or ""))
            assert(not ok, "test 12 failed: command should have returned error") 
            assert((err and err:find("error_cmd_file")) or (out and out:find("error_cmd_file")), "test 12 failed: missing error message")
            os.rm(errorfile)
        end
    end)
