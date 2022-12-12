#ifdef MSVC_MODULES
import std.core;
#else
import std;
#endif

import my_module;

using namespace std;

int main(int argc, char** argv) {
    cout << my_sum(1, 1) << endl;
}
