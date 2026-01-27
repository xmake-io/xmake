#pragma once

#include <iostream>
#include <list>
#include <numeric>

// PCH with .tcc extension
inline void hello_from_tcc() {
    std::cout << "Hello from .tcc PCH!" << std::endl;
}

template<typename T>
class TCCCalculator {
private:
    std::list<T> values;
    
public:
    void add(const T& value) {
        values.push_back(value);
    }
    
    T sum() const {
        return std::accumulate(values.begin(), values.end(), T(0));
    }
    
    double average() const {
        if (values.empty()) return 0.0;
        return static_cast<double>(sum()) / values.size();
    }
    
    void clear() {
        values.clear();
    }
    
    void print() const {
        std::cout << "Values: ";
        for (const auto& value : values) {
            std::cout << value << " ";
        }
        std::cout << std::endl;
    }
};
