#include <iostream>

using namespace std;

extern unsigned char data[];

int main(int argc, char** argv) {
    cout << (const char*)data << endl;
    return 0;
}
