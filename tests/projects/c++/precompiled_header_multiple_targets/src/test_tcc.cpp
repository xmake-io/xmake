#include "pch_test.tcc"

int main() {
    hello_from_tcc();
    
    TCCCalculator<double> calc;
    calc.add(3.5);
    calc.add(7.2);
    calc.add(1.8);
    calc.add(9.6);
    calc.add(4.1);
    
    calc.print();
    std::cout << "Sum: " << calc.sum() << std::endl;
    std::cout << "Average: " << calc.average() << std::endl;
    
    // Test with integers
    TCCCalculator<int> int_calc;
    int_calc.add(10);
    int_calc.add(20);
    int_calc.add(30);
    
    int_calc.print();
    std::cout << "Sum: " << int_calc.sum() << std::endl;
    std::cout << "Average: " << int_calc.average() << std::endl;
    
    return 0;
}
