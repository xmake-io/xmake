#include "pch_test.ipp"

int main() {
    hello_from_ipp();
    
    IPPContainer<int> container;
    container.add(1);
    container.add(2);
    container.add(3);
    
    std::cout << "Container contents: ";
    container.print();
    
    return 0;
}
