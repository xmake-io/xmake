#include <reg52.h>

#define REP(i, j) for(i = 0; i < j; ++i)
sbit control = P3 ^ 2;

void delay_ms(unsigned int n) {
    unsigned int i, j;
    for (j = n; j > 0; j--)
        for (i = 112; i > 0; i--);
}

/*——————宏定义——————*/
int i;

void set(unsigned int x) {
    P1 = x;
    delay_ms(100);
}

void left_fill() {
    REP(i, 8) set(0xFF >> i);
}

void right_fill() {
    REP(i, 8) set((0xFF >> (7 - i)) ^ 0xFF);
}

void left_erase() {
    REP(i, 8) set((0xFF >> (7 - i)));
}

void right_erase() {
    REP(i, 8) set((0xFF >> i) ^ 0xFF);
}

int main() {
    P1 = 0xFF;
    P3 = 0xFF;
    while (1) {
        if (control == 0) {
            left_fill();
            left_erase();
            right_fill();
            right_erase();
        } else {
            set(0x55);
            set(0xAA);
        }
    }
}