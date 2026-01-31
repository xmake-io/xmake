target("test")
    set_kind("phony")
    on_run(function (target)
        import("core.base.option")
        local xmake = os.programfile()
        local xmake_dir = os.getenv("XMAKE_PROGRAM_DIR")
        print("XMAKE_PROGRAM_DIR: " .. (xmake_dir or "nil"))
        print("xmake binary: " .. xmake)
        
        local function run_with_env(cmd_str)
            local outfile = os.tmpfile()
            local errfile = os.tmpfile()
            local shell_cmd = cmd_str
            if xmake_dir then
                shell_cmd = string.format("export XMAKE_PROGRAM_DIR='%s' && %s", xmake_dir, cmd_str)
            end
            -- Redirect in shell using subshell to capture all output
            shell_cmd = string.format("(%s) > %s 2> %s", shell_cmd, outfile, errfile)
            
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

            local out = io.readfile(outfile)
            local err = io.readfile(errfile)
            
            os.rm(outfile)
            os.rm(errfile)
            
            return (code == 0), out, err
        end

        local function run_with_pwsh(cmd_str)
            local outfile = os.tmpfile()
            local errfile = os.tmpfile()
            local shell_cmd = cmd_str
            if xmake_dir then
                shell_cmd = string.format("$env:XMAKE_PROGRAM_DIR='%s'; %s", xmake_dir, cmd_str)
            end
            -- Redirect in shell using block to capture all output
            -- Note: We must explicitly exit with $LASTEXITCODE because pwsh script blocks 
            -- do not automatically propagate native command exit codes to process exit status.
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

            local out = io.readfile(outfile)
            local err = io.readfile(errfile)
            
            os.rm(outfile)
            os.rm(errfile)
            
            return (code == 0), out, err
        end

        -- check if feature is present
        local ok, out, err = run_with_env(string.format("%s lua --help", xmake))
        if out and out:find("--from-stdin", 1, true) then
            print("Feature presence check: PASS")
        else
            print("Feature presence check: FAIL")
            print("Help output:\n" .. (out or ""))
            print("Help error:\n" .. (err or ""))
        end

        -- test 1: pipe a few lines of lua code from echo
        local pipe_cmd = string.format("echo 'print(\"hello from pipe\")' | %s lua --from-stdin", xmake)
        print("running: " .. pipe_cmd)
        ok, out, err = run_with_env(pipe_cmd)
        print("STDOUT 1:\n" .. (out or ""))
        print("STDERR 1:\n" .. (err or ""))
        assert(ok, "test 1 failed: command returned error")
        if out then
            assert(out:find("hello from pipe"), "test 1 failed: output mismatch")
        end

        -- test 2: redirect from a .lua file
        local scriptfile = path.join(os.curdir(), "test.lua")
        io.writefile(scriptfile, 'print("hello from file")')
        local redirect_cmd = string.format("%s lua --from-stdin < %s", xmake, scriptfile)
        print("running: " .. redirect_cmd)
        ok, out, err = run_with_env(redirect_cmd)
        print("STDOUT 2:\n" .. (out or ""))
        print("STDERR 2:\n" .. (err or ""))
        assert(ok, "test 2 failed: command returned error")
        if out then
            assert(out:find("hello from file"), "test 2 failed: output mismatch")
        end
        os.rm(scriptfile)

        -- test 3: verify traceback on error via pipe
        local error_pipe_cmd = string.format("echo 'raise(\"error_pipe\")' | %s lua --from-stdin", xmake)
        print("running: " .. error_pipe_cmd)
        ok, out, err = run_with_env(error_pipe_cmd)
        print("STDOUT 3:\n" .. (out or ""))
        print("STDERR 3:\n" .. (err or ""))
        assert(not ok, "test 3 failed: command should have returned error") 
        assert((err and err:find("error_pipe")) or (out and out:find("error_pipe")), "test 3 failed: missing error message")

        -- test 4: verify traceback on error via file
        local errorfile = path.join(os.curdir(), "error.lua")
        io.writefile(errorfile, 'raise("error_file")')
        local error_file_cmd = string.format("%s lua --from-stdin < %s", xmake, errorfile)
        print("running: " .. error_file_cmd)
        ok, out, err = run_with_env(error_file_cmd)
        print("STDOUT 4:\n" .. (out or ""))
        print("STDERR 4:\n" .. (err or ""))
        assert(not ok, "test 4 failed: command should have returned error")
        assert((err and err:find("error_file")) or (out and out:find("error_file")), "test 4 failed: missing error message")
        os.rm(errorfile)

        -- pwsh tests
        if os.execv("pwsh", {"-v"}) == 0 then
            print("pwsh detected, running pwsh tests...")
            
            -- test 5: pwsh pipe success
            -- Note: quoting for pwsh inside lua string inside pwsh -c requires care.
            -- We want pwsh to execute: Write-Output "print(`"hello from pwsh pipe`")" | & 'xmake' ...
            -- In Lua string: "Write-Output \"print(`\"hello from pwsh pipe`\")\""
            local pwsh_pipe_cmd = string.format("Write-Output \"print(`\"hello from pwsh pipe`\")\" | & '%s' lua --from-stdin", xmake)
            print("running pwsh: " .. pwsh_pipe_cmd)
            ok, out, err = run_with_pwsh(pwsh_pipe_cmd)
            print("STDOUT 5:\n" .. (out or ""))
            print("STDERR 5:\n" .. (err or ""))
            assert(ok, "test 5 failed: command returned error")
            if out then
                assert(out:find("hello from pwsh pipe"), "test 5 failed: output mismatch")
            end

            -- test 6: pwsh file redirect success (using Get-Content as pipe)
            local scriptfile = path.join(os.curdir(), "test_pwsh.lua")
            io.writefile(scriptfile, 'print("hello from pwsh file")')
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

            -- test 7: pwsh pipe error
            local pwsh_error_pipe_cmd = string.format("Write-Output \"raise(`\"error_pwsh_pipe`\")\" | & '%s' lua --from-stdin", xmake)
            print("running pwsh: " .. pwsh_error_pipe_cmd)
            ok, out, err = run_with_pwsh(pwsh_error_pipe_cmd)
            print("STDOUT 7:\n" .. (out or ""))
            print("STDERR 7:\n" .. (err or ""))
            assert(not ok, "test 7 failed: command should have returned error") 
            assert((err and err:find("error_pwsh_pipe")) or (out and out:find("error_pwsh_pipe")), "test 7 failed: missing error message")

            -- test 8: pwsh file redirect error
            local errorfile = path.join(os.curdir(), "error_pwsh.lua")
            io.writefile(errorfile, 'raise("error_pwsh_file")')
            local pwsh_error_file_cmd = string.format("Get-Content '%s' | & '%s' lua --from-stdin", errorfile, xmake)
            print("running pwsh: " .. pwsh_error_file_cmd)
            ok, out, err = run_with_pwsh(pwsh_error_file_cmd)
            print("STDOUT 8:\n" .. (out or ""))
            print("STDERR 8:\n" .. (err or ""))
            assert(not ok, "test 8 failed: command should have returned error") 
            assert((err and err:find("error_pwsh_file")) or (out and out:find("error_pwsh_file")), "test 8 failed: missing error message")
            os.rm(errorfile)
        else
            print("pwsh not found, skipping pwsh tests")
        end
    end)
