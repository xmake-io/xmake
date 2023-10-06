#include <iostream>

using namespace std;

int main(int argc, char** argv)
{
    char const* arg = argc > 1? argv[1] : "xmake";
    cout << "hello " << arg << endl;
    return 0;
}
