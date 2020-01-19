-- project
set_project("xmake")

-- version
set_version("2.2.9", {build = "%Y%m%d%H%M"})

-- set xmake min version
set_xmakever("2.2.3")

-- only build core project
includes("core")
