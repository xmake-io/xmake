add_requires("cmake")
add_requires("python")
if is_host("linux", "bsd", "macosx") then
    add_requires("pkg-config", "autoconf", "automake", "libtool")
elseif is_host("windows") then
    set_toolchains("msvc")
end
