#include <iostream>
#include <numeric>
#include <stdexcept>
#include <vector>
extern "C" int helper(void);
extern "C" int shared_value(void);
int main() {
    std::vector<int> values{1, 2, 3};
    try { throw std::runtime_error("xclang"); }
    catch (const std::runtime_error& e) {
        if (std::string(e.what()) != "xclang") return 1;
    }
    if (helper() != 42 || shared_value() != 6 || std::accumulate(values.begin(), values.end(), 0) != 6) return 2;
    std::cout << "xclang smoke passed" << std::endl;
}
