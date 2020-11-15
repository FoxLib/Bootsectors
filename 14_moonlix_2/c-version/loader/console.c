// // gcc -c -masm=intel -m32 -fno-asynchronous-unwind-tables console.c -S

#include <stdint.h> 
#define BRK asm("xchg bx, bx");

// http://wiki.osdev.org/Text_Mode_Cursor 
// col = 0..79, row=0..24
void update_cursor(uint8_t row, uint8_t col)
 {
    uint16_t position = (row*80) + col;
 
    // cursor LOW port to vga INDEX register
    outb(0x3D4, 0x0F);
    outb(0x3D5, (unsigned char)(position & 0xFF));

    // cursor HIGH port to vga INDEX register
    outb(0x3D4, 0x0E);
    outb(0x3D5, (unsigned char)((position >> 8) & 0xFF));
}

// Консольный вывод
void cwchar(uint8_t x, uint8_t y, char c, uint8_t attr)
{
    // 0x18000 -- начало текстовой видеопамяти
    uint32_t ptr = (y*80 + x) * 2 + 0x18000;

    // Записать символ в видеопамять
    asm("mov edi, %0" : : "m" (ptr));
    asm("mov [gs:edi + 0], %0" : : "r"(c));
    asm("mov [gs:edi + 1], %0" : : "r"(attr));
}

// Записать атрибут
void cwattr(uint8_t x, uint8_t y, uint8_t attr)
{
    writeb_gs(2*(x + 80*y) + 1 + 0x18000, attr);
}

// Считать атрибут
uint8_t rdattr(uint8_t x, uint8_t y)
{
    return read_gs(2*(x + 80*y) + 1 + 0x18000);
}
 
// Очистка экрана в определенный цвет
void coclear(uint8_t attr) 
{
    int i, j;
    for (i = 0; i < 25; i++) {
        for (j = 0; j < 80; j++) {
            cwchar(j, i, ' ', attr);
        }
    }
}

// Консольный вывод строки
void coprintf(uint8_t x, uint8_t y, char* str, uint8_t attr)
{
    int i = 0;

    while (str[i]) 
    {       
        cwchar(x, y, str[i], attr);
    
        x++;
        if (x > 79) 
            { x = 0; y++; }
        if (y > 24) { 
            y = 0; 
            // перемотка вниз
        }

        i++;
    }   
}

// x, y, hex - число, attr - атрибуты, bits = 32/16/8
void coprinth(uint8_t x, uint8_t y, uint32_t hex, uint8_t attr, uint8_t bits) 
{
    int i, p;

    for (i = 0; i < bits / 4; i++) 
    {
        if (bits == 32) {
            p = ((hex & 0xf0000000) >> 28) & 0xf;
        } 
        else if (bits == 16) {
            p = ((hex & 0xf000) >> 12) & 0xf;
        }
        else if (bits == 8) {
            p = ((hex & 0xf0) >> 4) & 0xf;
        }
        
        cwchar(x + i, y, p < 10 ? (p + '0') : p + '0' + 7, attr);
        hex <<= 4;
    }
}

// Вывод логотипа Moonix
void conlogotype()
{
    uint32_t i, j, w;
    uint32_t logo[8] = { 
        0b0000000011111000,
        0b0000000000111110,
        0b0110110010011111,
        0b0101010111011111,
        0b0101010010011111,
        0b0000000000111110,
        0b0000000011111000,
        0b0000000000000000
    };

    for (i = 0; i < 8; i++)
    {
        w = logo[i];
        for (j = 0; j < 16; j++)
        {
            cwchar(63 + j, 1 + i, ' ', (w & 0x8000 ? (i < 4 ? 0x70 : 0x30) : 0x00));
            asm("shl %0, 1" : "=m"(w)); // Из-за неправильной трансляции в FASM (sal dword)
        }
    }

    coprintf(63, 7, "Moonlix", 0x07);
}