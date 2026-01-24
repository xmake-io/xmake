#include "lib2_pch.h"

int lib2_function() {
    std::map<int, std::string> data = {{1, "one"}, {2, "two"}, {3, "three"}};
    std::set<int> keys;
    
    for (const auto& pair : data) {
        keys.insert(pair.first);
    }
    
    return keys.size();
}
