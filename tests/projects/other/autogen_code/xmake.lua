add_rules("mode.debug", "mode.release")

target("test")
    set_kind("binary")
    add_files("$(buildir)/autogen.cpp", {always_added = true})
    before_build(function (target)
        io.writefile("$(buildir)/autogen.cpp", [[
#include <iostream>
using namespace std;
int main(int argc, char** argv) {
    cout << "hello world!" << endl;
    return 0;
}
        ]])
    end)


