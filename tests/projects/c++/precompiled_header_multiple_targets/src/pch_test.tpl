#pragma once

#include <iostream>
#include <queue>
#include <stack>

// PCH with .tpl extension
inline void hello_from_tpl() {
    std::cout << "Hello from .tpl PCH!" << std::endl;
}

template<typename T>
class TPLProcessor {
private:
    std::queue<T> input_queue;
    std::stack<T> output_stack;
    
public:
    void enqueue(const T& item) {
        input_queue.push(item);
    }
    
    T dequeue() {
        if (input_queue.empty()) return T();
        T item = input_queue.front();
        input_queue.pop();
        return item;
    }
    
    void push_to_stack(const T& item) {
        output_stack.push(item);
    }
    
    T pop_from_stack() {
        if (output_stack.empty()) return T();
        T item = output_stack.top();
        output_stack.pop();
        return item;
    }
    
    void transfer_to_stack() {
        while (!input_queue.empty()) {
            push_to_stack(dequeue());
        }
    }
    
    void print_queue() const {
        std::queue<T> temp = input_queue;
        std::cout << "Queue: ";
        while (!temp.empty()) {
            std::cout << temp.front() << " ";
            temp.pop();
        }
        std::cout << std::endl;
    }
    
    void print_stack() const {
        std::stack<T> temp = output_stack;
        std::cout << "Stack: ";
        while (!temp.empty()) {
            std::cout << temp.top() << " ";
            temp.pop();
        }
        std::cout << std::endl;
    }
};
