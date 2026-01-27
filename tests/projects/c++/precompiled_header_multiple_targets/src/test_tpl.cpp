#include "pch_test.tpl"

int main() {
    hello_from_tpl();
    
    TPLProcessor<std::string> processor;
    
    // Add items to queue
    processor.enqueue("first");
    processor.enqueue("second");
    processor.enqueue("third");
    
    processor.print_queue();
    
    // Transfer to stack
    processor.transfer_to_stack();
    processor.print_queue();
    processor.print_stack();
    
    // Pop from stack (LIFO order)
    std::cout << "Popping from stack:" << std::endl;
    while (true) {
        std::string item = processor.pop_from_stack();
        if (item.empty()) break;
        std::cout << "  " << item << std::endl;
    }
    
    // Test with integers
    TPLProcessor<int> int_processor;
    int_processor.enqueue(100);
    int_processor.enqueue(200);
    int_processor.enqueue(300);
    
    int_processor.transfer_to_stack();
    std::cout << "Integer stack pop:" << std::endl;
    while (true) {
        int item = int_processor.pop_from_stack();
        if (item == 0) break;
        std::cout << "  " << item << std::endl;
    }
    
    return 0;
}
