
local cflags = {
	"-mcpu=cortex-m4",
	" -mthumb",
	"-mfloat-abi=hard  -mfpu=fpv4-sp-d16",
	"-fdata-sections -ffunction-sections",
	"-nostartfiles",
	"-Os",
}

local ldflags = {
	"-specs=nano.specs",
	"-lc",
	"-lm",
	"-lnosys",
	"-Wl,--gc-sections",
}

function use_toolchain(sdk_path)
	toolchain("arm-gcc")
		set_kind("cross")
		set_description("Stm32 Arm Embedded Compiler")
		set_sdkdir(sdk_path)
		set_toolset("cc", "arm-none-eabi-gcc")
		set_toolset("ld", "arm-none-eabi-gcc")
		set_toolset("ar", "arm-none-eabi-ar")
		set_toolset("as", "arm-none-eabi-gcc")
	toolchain_end()
	set_toolchains("arm-gcc")
end

rule("arm-gcc")
	on_load(function (target)
		-- force add ld flags, ldflags {force = true}
		target:set("policy", "check.auto_ignore_flags", false)
		target:add("cxflags", cflags)
		target:add("asflags", cflags)
		-- use gcc to link
		target:add("ldflags", cflags)
		target:add("ldflags", ldflags)
	end)
	
	after_build(function (target)
		print("$(env ARM_TOOL)")
		print("after_build: generate hex files")
		local out = target:targetfile() or ""
		local gen_fi = "build/"..target:name()
		print(string.format("%s => %s", out, gen_fi))
		os.exec("arm-none-eabi-objcopy -Obinary "..out.." "..gen_fi..".bin")
		-- https://github.com/xmake-io/xmake/discussions/2125
		-- os.exec("arm-none-eabi-objdump -S "..out.." > "..gen_fi..".asm")
		-- local asm = os.iorun("arm-none-eabi-objdump -S build/cross/cortex-m4/release/minimal-proj")
		-- io.writefile(gen_fi..".asm", asm)
		os.execv("arm-none-eabi-objdump", {"-S", out}, {stdout=gen_fi..".asm"})
		os.exec("arm-none-eabi-objcopy -O ihex "..out.." "..gen_fi..".hex")
		--  -I binary
		-- $(Q) $(OBJ_COPY) -O ihex $@ $(BUILD_DIR)/$(TARGET).hex
		-- $(Q) $(OBJ_COPY) -O binary $@ $(BUILD_DIR)/$(TARGET).bin
		-- os.exec("qemu-system-arm -M stm32-p103 -nographic -kernel"..bin_out)
	end)
	after_clean(function (target)
		local gen_fi = "build/"..target:name()
		os.rm(gen_fi..".*")
	end)
rule_end()

task("qemu")
	on_run(function ()
		print("Run binary in Qemu!")
		local bin_out = os.files("$(buildir)/*.bin")[1]
		if bin_out then
			os.exec("qemu-system-arm -M stm32-p103 -nographic -kernel "..bin_out)
		else
			print("Do not find bin file in $(buildir)/")
		end
	end)
	set_menu {
		-- Settings menu usage
		usage = "xmake qemu",

		-- Setup menu description
		description = "Run binary in Qemu!"
	}
task_end()