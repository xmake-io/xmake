#include <iostream>
#include <fstream>
#include <vector>

using namespace std;

int main(int argc, char** argv) {
    ifstream src_file(argv[1], ios::in | ios::binary);
    if (!src_file) {
        return 1;
    }
    vector<char> buffer(istreambuf_iterator<char>(src_file), {});
    src_file.close();

    ofstream dst_file(argv[2], ios::out);
    if (!dst_file) {
        return 1;
    }

    dst_file << "unsigned char g_codegen_data[] = {";
    for (auto byte : buffer) {
        dst_file << "0x" << hex << (int)(unsigned char)byte << ",";
    }
    dst_file << "0};" << endl;
    dst_file.close();
    return 0;
}

