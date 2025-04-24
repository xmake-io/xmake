add_rules("mode.debug", "mode.release")

target("test")
    set_kind("binary")
    add_files("$(builddir)/autogen.cpp", {always_added = true})
    before_build(function (target)
        io.writefile("$(builddir)/autogen.cpp", [[
#include <iostream>
using namespace std;
int main(int argc, char** argv) {
    cout << "hello world!" << endl;
    return 0;
}
        ]])
    end)


