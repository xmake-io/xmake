﻿#include <iostream>

import BasicPlane.Figures;

int main(int argc, char** argv) {
    Rectangle r{ {1,8}, {11,3} };
    std::cout << "area: " << area(r) << '\n';
    std::cout << "width: " << width(r) << '\n';
    return 0;
}
