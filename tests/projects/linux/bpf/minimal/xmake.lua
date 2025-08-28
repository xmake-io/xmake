add_rules("mode.release", "mode.debug")
add_rules("platform.linux.bpf")

add_requires("linux-tools", {configs = {bpftool = true}})
add_requires("libbpf")
if is_plat("android") then
    add_requires("ndk >=22.0 <26.0")
    set_toolchains("@ndk", {sdkver = "23"})
else
    add_requires("llvm >=10.x")
    set_toolchains("@llvm")
    add_requires("linux-headers")
end

-- fix error: libbpf: map 'my_pid_map': unsupported map linkage static. for bpftool >= 7.2.0
-- we cannot add `"-fvisibility=hidden"` when compiling *.bpf.c
-- @see https://github.com/libbpf/bpftool/issues/120
set_symbols("none")

target("minimal")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("linux-tools", "linux-headers", "libbpf")
    set_license("GPL-2.0")
