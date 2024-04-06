package("bar")
    set_sourcedir(path.join(os.scriptdir(), "src"))

    on_install(function(package)
        import("package.tools.xmake").install(package, {})
    end)

    on_test(function(package)
         assert(package:check_cxxsnippets({test = [[
             #include <iostream>
             void test() {
                 std::cout << _LIBCPP_VERSION << std::endl;
             }
         ]]}, {configs = {languages = "c++17"}}))
    end)
