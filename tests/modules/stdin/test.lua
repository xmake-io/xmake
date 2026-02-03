import("lib.detect.find_tool")

function _run_sh(t, name, cmd, expect)
    if not is_host("windows") then
        local xmake = path.translate(os.programfile())
        local run_stdin = string.format('"%s" l --stdin', xmake)
        local outdata = os.iorunv("sh", {"-c", cmd .. " | " .. run_stdin}) or ""
        t:are_equal(outdata:trim(), expect)
    end
end

function _run_cmd(t, name, cmd, expect)
    if is_host("windows") then
        local xmake = path.translate(os.programfile())
        local run_stdin = string.format('%s l --stdin', xmake)
        local outdata = os.iorunv("cmd", {"/c", cmd .. " | " .. run_stdin}) or ""
        t:are_equal(outdata:trim(), expect)
    end
end

function _run_pwsh(t, name, cmd, expect)
    if is_host("windows") then
        local xmake = path.translate(os.programfile())
        local run_stdin = string.format('%s l --stdin', xmake)
        local pwsh = find_tool("powershell")
        if pwsh then
            local outdata = os.iorunv(pwsh.program, {"-c", cmd .. " | " .. run_stdin}) or ""
            t:are_equal(outdata:trim(), expect)
        end
    end
end

function test_sh(t)
    _run_sh(t, "sh_single", "echo \"print('hello_sh')\"", "hello_sh")
    _run_sh(t, "sh_calc", "echo \"local f = 1+1; print(f)\"", "2")
    _run_sh(t, "sh_main", "echo \"function main() print('in_sh_main') end\"", "in_sh_main")
    _run_sh(t, "sh_multi", "printf \"print('shell_line1')\\nprint('shell_line2')\"", "shell_line1\nshell_line2")
end

function test_cmd(t)
    _run_cmd(t, "cmd_single", "echo print 'hello_cmd'", "hello_cmd")
    _run_cmd(t, "cmd_calc", "echo local f = 1+1; print(f)", "2")
    _run_cmd(t, "cmd_multi_lines", "(echo print 'line1' && echo print 'line2')", "line1\nline2")
    _run_cmd(t, "cmd_multi_semicolon", "echo print('semi1'); print('semi2')", "semi1\nsemi2")
end

function test_pwsh(t)
    _run_pwsh(t, "pwsh_single", "echo \"print('hello_pwsh')\"", "hello_pwsh")
    _run_pwsh(t, "pwsh_calc", "echo \"local f = 1+1; print(f)\"", "2")
    _run_pwsh(t, "pwsh_main", "echo \"function main() print('in_pwsh_main') end\"", "in_pwsh_main")
    _run_pwsh(t, "pwsh_multi", "echo \"print('pline1')\"; echo \"print('pline2')\"", "pline1\npline2")
end
