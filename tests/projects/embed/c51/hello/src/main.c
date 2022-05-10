//
// Created by DawnManget on 2022/5/10.
//
#include <reg52.h>
sbit light = P0 ^ 3;
void main() {
    light = 0;
    while (1);
}