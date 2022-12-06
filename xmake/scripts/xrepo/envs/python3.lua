if is_host("windows") and winos.version():le("win7") then
    add_requires("python 3.7.x")
else
    add_requires("python 3.x")
end
