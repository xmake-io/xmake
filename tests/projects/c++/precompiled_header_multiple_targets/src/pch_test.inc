#pragma once

#include <iostream>
#include <string>
#include <map>

// PCH with .inc extension
#define APP_NAME "PCH Test"
#define VERSION "1.0"

inline void hello_from_inc() {
    std::cout << "Hello from .inc PCH!" << std::endl;
}

template<typename K, typename V>
class INCMap {
private:
    std::map<K, V> data;
    
public:
    void insert(const K& key, const V& value) {
        data[key] = value;
    }
    
    V get(const K& key) const {
        auto it = data.find(key);
        return (it != data.end()) ? it->second : V();
    }
    
    void print_info() const {
        std::cout << APP_NAME << " v" << VERSION << std::endl;
        std::cout << "Map contains " << data.size() << " items" << std::endl;
    }
};
