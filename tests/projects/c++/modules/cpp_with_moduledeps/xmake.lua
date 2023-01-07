add_rules("mode.release", "mode.debug")
set_languages("c++20")

target("mod")
  set_kind("static")
  add_files("src/mod.mpp", "src/mod.cpp")

target("cpp_with_moduledeps")
  set_kind("binary")
  add_deps("mod")
  add_files("src/main.cpp")
