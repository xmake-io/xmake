add_repositories("my-repo my-repo")
add_requires("bar")

target("foo")
    set_kind("binary")
    add_files("src/*.cpp")
    
    add_packages("bar")

    on_config(function(target)
         assert(target:check_cxxsnippets({test = [[
             #include <iostream>
             void test() {
                 std::cout << _LIBCPP_VERSION << std::endl;
             }
         ]]}, {configs = {languages = "c++17"}}))
    end)

