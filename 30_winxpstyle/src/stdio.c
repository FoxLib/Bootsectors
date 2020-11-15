#include "stddef.h"
#include "stdio.h"
#include "vga.h"

// Печать строки
int print(char* s) {

    int i = 0, n = 0;
    while (s[i]) {

        unsigned char ch = s[i++];

        if (ch == 0xD0) { // Главный набор

            ch = s[i++];
            ch = (ch == 0x81 ? 0xF0 : ch - 0x10);

        } else if (ch == 0xD1) { // Вторичный набор

            ch = s[i++];
            ch = (ch == 0x91 ? 0xF1 : ch + (ch < 0xB0 ? 0x60 : 0x10));
        }

        print_char(ch);
        n++;
    }

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
