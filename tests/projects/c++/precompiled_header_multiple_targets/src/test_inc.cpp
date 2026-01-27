#include "pch_test.inc"

int main() {
    hello_from_inc();
    
    INCMap<std::string, int> scores;
    scores.insert("alice", 95);
    scores.insert("bob", 87);
    scores.insert("charlie", 92);
    
    scores.print_info();
    std::cout << "Alice's score: " << scores.get("alice") << std::endl;
    std::cout << "Bob's score: " << scores.get("bob") << std::endl;
    
    return 0;
}
