#include "common.h"

int lib1_function();
int lib2_function();

int main() {
    std::cout << "Main program started" << std::endl;
    
    int result1 = lib1_function();
    int result2 = lib2_function();
    
    std::cout << "lib1 result: " << result1 << std::endl;
    std::cout << "lib2 result: " << result2 << std::endl;
    
    std::vector<int> vec = {result1, result2};
    std::cout << "Combined result: " << vec[0] + vec[1] << std::endl;
    
    return 0;
}
