add_rules("mode.release", "mode.debug")
add_rules("platform.linux.bpf")

add_requires("linux-tools", {alias = "bpftool", host = true, configs = {bpftool = true}})
add_requires("libbpf", "linux-headers")
if not is_plat("android") then
    add_requires("llvm >=10.x")
    set_toolchains("@llvm")
end

target("minimal")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("bpftool", "libbpf", "linux-headers")
    set_license("GPL-2.0")
