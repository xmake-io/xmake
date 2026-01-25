#include <iostream>

// Declare the function from lib1
int lib1_function();

int main() {
    std::cout << "Consumer program without PCH" << std::endl;
    int result = lib1_function();
    std::cout << "lib1 result: " << result << std::endl;
    return 0;
}
