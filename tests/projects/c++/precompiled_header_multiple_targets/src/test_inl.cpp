#include "pch_test.inl"

int main() {
    hello_from_inl();
    
    INLProcessor<int> processor;
    processor.add(42);
    processor.add(17);
    processor.add(89);
    processor.add(3);
    processor.add(56);
    
    std::cout << "Original: ";
    processor.print();
    
    processor.sort();
    std::cout << "Sorted:   ";
    processor.print();
    
    std::cout << "Min: " << processor.min() << std::endl;
    std::cout << "Max: " << processor.max() << std::endl;
    
    return 0;
}
