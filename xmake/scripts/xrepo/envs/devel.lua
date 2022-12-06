add_requires("cmake")
if is_host("windows") and winos.version():le("win7") then
    add_requires("python 3.7.x")
else
    add_requires("python 3.x")
end
if is_host("linux", "bsd", "macosx") then
    add_requires("pkg-config", "autoconf", "automake", "libtool")
elseif is_host("windows") then
    set_toolchains("msvc")
end
