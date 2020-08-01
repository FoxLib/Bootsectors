#include "stddef.h"
#include "stdio.h"
#include "vga.h"

// Печать строки
int print(char* s) {

    int n = 0;
    while (s[n]) { print_char(s[n]); n++;}
    return n;
}

// Печать HEX
void printhex(uint32_t val, int sz) {

    while (sz > 0) {
        sz -= 4;
        uint8_t m = (val >> sz) & 0x0F;
        print_char((m < 10 ? '0' : '7') + m);
    }
}
