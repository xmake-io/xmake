#include "tool_pch.h"

int main() {
    std::stringstream ss;
    ss << "Tool program output";
    
    std::ofstream outfile("tool_output.txt");
    if (outfile.is_open()) {
        outfile << ss.str() << std::endl;
        outfile.close();
    }
    
    std::cout << "Tool completed successfully" << std::endl;
    return 0;
}
