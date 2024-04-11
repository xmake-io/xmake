#include <iostream>

using namespace std;

extern unsigned char g_codegen_data[];

int main(int argc, char** argv) {
    cout << (const char*)g_codegen_data << endl;
    return 0;
}
