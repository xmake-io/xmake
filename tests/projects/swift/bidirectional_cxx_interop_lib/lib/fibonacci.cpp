#include <fibonacci/fibonacci.h>
#include <fibonacci-Swift.h>
#include <iostream>

extern "C" int fibonacci_cpp(int x) {
  std::cout << "x [cpp]: " << x << std::endl;
  if (x <= 1) return 1;
  return SwiftFibonacci::fibonacciSwift(x - 1) + SwiftFibonacci::fibonacciSwift(x - 2);
}
