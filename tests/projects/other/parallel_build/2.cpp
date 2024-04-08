// Make this object complex and cost longer compile time...
#include <algorithm>
#include <any>
#include <bitset>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <list>
#include <map>
#include <optional>
#include <queue>
#include <string>
#include <unordered_map>
#include <variant>
#include <vector>

int main() {
  
  using Type = std::variant<int8_t, uint8_t, int16_t, uint16_t, int32_t,
                            uint32_t, int64_t, uint64_t, double, float>;
  Type a, b, c;
  a = 5;
  b = 3.0;
  c = 4.0f;
  double r;
  std::visit([&](auto a, auto b, auto c) { r = a + b + c; }, a, b, c);
  std::visit([&](auto a, auto b, auto c) { r = a + b - c; }, a, b, c);
  std::visit([&](auto a, auto b, auto c) { r = a - b - c; }, a, b, c);
  std::visit([&](auto a, auto b, auto c) { r = (a + b + c) * 2; }, a, b, c);
  std::visit([&](auto a, auto b, auto c) { r = (a + b - c) * 3; }, a, b, c);
}