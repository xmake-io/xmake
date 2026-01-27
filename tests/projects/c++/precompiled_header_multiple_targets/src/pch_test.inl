#pragma once

#include <iostream>
#include <vector>
#include <algorithm>

// PCH with .inl extension
inline void hello_from_inl() {
    std::cout << "Hello from .inl PCH!" << std::endl;
}

template<typename T>
class INLProcessor {
private:
    std::vector<T> items;
    
public:
    void add(const T& item) {
        items.push_back(item);
    }
    
    void sort() {
        std::sort(items.begin(), items.end());
    }
    
    T max() const {
        if (items.empty()) return T();
        return *std::max_element(items.begin(), items.end());
    }
    
    T min() const {
        if (items.empty()) return T();
        return *std::min_element(items.begin(), items.end());
    }
    
    void print() const {
        for (const auto& item : items) {
            std::cout << item << " ";
        }
        std::cout << std::endl;
    }
};
