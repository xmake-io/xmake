#include "lib1_pch.h"

int lib1_function() {
    std::vector<int> numbers = {1, 2, 3, 4, 5};
    int sum = std::accumulate(numbers.begin(), numbers.end(), 0);
    return sum;
}
