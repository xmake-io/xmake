#pragma once

#include <iostream>
#include <string>
#include <vector>

// PCH with .ipp extension
inline void hello_from_ipp() {
    std::cout << "Hello from .ipp PCH!" << std::endl;
}

template<typename T>
class IPPContainer {
private:
    std::vector<T> data;
    
public:
    void add(const T& item) {
        data.push_back(item);
    }
    
    void print() const {
        for (const auto& item : data) {
            std::cout << item << " ";
        }
        std::cout << std::endl;
    }
};
