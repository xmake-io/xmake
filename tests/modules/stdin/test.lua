function main(t)
	local xmake = path.unix(os.programfile())
	if os.host() == "windows" then
		xmake = xmake:gsub("/", "\\")
	end

	local function test_shell(name, cmd, expect)
		print("testing " .. name .. ": " .. cmd)
		local outfile = os.tmpfile()
		local errfile = os.tmpfile()
		local full_cmd = string.format('%s > "%s" 2> "%s"', cmd, outfile, errfile)
		local ret = -1
		try({
			function()
				if os.host() ~= "windows" then
					ret = os.execv("sh", { "-c", full_cmd })
				else
					ret = os.exec(full_cmd)
				end
			end,
		})
		local out = ""
		if os.isfile(outfile) then
			out = io.readfile(outfile)
			if out and out:find("\0", 1, true) then
				out = out:gsub("\0", "")
			end
		end
		local err = ""
		if os.isfile(errfile) then
			err = io.readfile(errfile)
		end
		local passed = out:find(expect)
		if passed then
			print("  -> passed")
		else
			print("  -> failed")
		end
		print("     out: " .. (out or ""))
		print("     err: " .. (err or ""))
		if not passed then
			raise("[test_stdin]: Test failed! Expect: ", expect)
		end
		os.tryrm(outfile)
		os.tryrm(errfile)
	end

	local pwsh = ""
	if os.host() == "windows" then
		-- Test cmd
		test_shell("cmd_single", string.format("cmd /c echo \"print('hello_cmd')\" | %s l --stdin", xmake), "hello_cmd")
		test_shell("cmd_calc", string.format('cmd /c echo "local f = 1+1; print(f)" | %s l --stdin', xmake), "2")
		test_shell(
			"cmd_multi",
			string.format("cmd /c echo \"print('line1')\\nprint('line2')\" | %s l --stdin", xmake),
			"line1[\r\n]+line2"
		)
		-- Test powershell (if available)
		local pwsh = "powershell"
		try({
			function()
				if os.exec("pwsh -v") == 0 then
					pwsh = "pwsh"
				end
			end,
		})
		test_shell(
			"pwsh_single",
			string.format('%s -c "echo \\"print(\'hello_pwsh\')\\" | %s l --stdin"', pwsh, xmake),
			"hello_pwsh"
		)
		test_shell(
			"pwsh_calc",
			string.format('%s -c "echo \\"local f = 1+1; print(f)\\" | %s l --stdin"', pwsh, xmake),
			"2"
		)
		test_shell(
			"pwsh_multi",
			string.format("%s -c \"echo \\\"print('pline1')\\nprint('pline2')\\\" | %s l --stdin\"", pwsh, xmake),
			"pline1[\r\n]+pline2"
		)
	else
		-- Linux/MacOS
		local pwsh = ""
		try({
			function()
				os.iorun("pwsh -v")
				pwsh = "pwsh"
			end,
		})
		if pwsh == "" then
			try({
				function()
					os.iorun("powershell -v")
					pwsh = "powershell"
				end,
			})
		end

		if pwsh ~= "" then
			test_shell(
				"pwsh_single",
				string.format('%s -c "echo \\"print(\'hello_pwsh\')\\" | %s l --stdin"', pwsh, xmake),
				"hello_pwsh"
			)
			test_shell(
				"pwsh_calc",
				string.format('%s -c "echo \\"local f = 1+1; print(f)\\" | %s l --stdin"', pwsh, xmake),
				"2"
			)
			test_shell(
				"pwsh_main",
				string.format(
					'%s -c "echo \\"function main() print(\'in_pwsh_main\') end\\" | %s l --stdin"',
					pwsh,
					xmake
				),
				"in_pwsh_main"
			)
			test_shell(
				"pwsh_multi",
				string.format(
					'%s -c "echo \\"print(\'pline1\')\\" \\"print(\'pline2\')\\" | %s l --stdin"',
					pwsh,
					xmake
				),
				"pline1[\r\n]+pline2"
			)
		end

		test_shell("sh_single", string.format("echo \"print('hello_sh')\" | %s l --stdin", xmake), "hello_sh")
		test_shell("sh_calc", string.format('echo "local f = 1+1; print(f)" | %s l --stdin', xmake), "2")
		test_shell(
			"sh_main",
			string.format("echo \"function main() print('in_sh_main') end\" | %s l --stdin", xmake),
			"in_sh_main"
		)
		test_shell(
			"sh_multi",
			string.format("printf \"print('shell_line1')\\nprint('shell_line2')\" | %s l --stdin", xmake),
			"shell_line1[\r\n]+shell_line2"
		)
	end
end
