#include "vga.h"

void bits_reset();
void cls(u8 k);

// Установка битовой карты по умолчанию (белый цвет)
inline void bits_reset() {
	
    IoWrite16(VGA_GC_INDEX, 0x0205);
    IoWrite16(VGA_GC_INDEX, 0xFF08);
}

// Полная очистка экрана
void cls(u8 k) {
    
    int i;
    
    bits_reset();
    for (i = 0; i < 38400; i++) {
        *((char*)0xA0000 + i) = (u8)k;
    }
}

// Простановка цвета пикселя 0..255 
// [R/G/B] 0xRRGGBB
void dac_set(u8 n, u32 c) {

    IoWrite8(VGA_DAC_WRITE_INDEX, n);
    IoWrite8(VGA_DAC_DATA, (c >> 18) & 0x3f);
    IoWrite8(VGA_DAC_DATA, (c >> 10) & 0x3f);
    IoWrite8(VGA_DAC_DATA, (c >> 2) & 0x3f);
}

// Принудительная запись с "защелкой" для срабатывания маски 
inline void flush_write(u32 addr, u8 c) {

    u8* m = (u8*)0xa0000;
    volatile u8 t = m[addr];
    m[addr] = c;
}

// Запись пикселя на экран
void pixel(u16 x, u16 y, u8 c) {

    IoWrite16(VGA_GC_INDEX, 0x0008 | (0x8000 >> (x & 7))); 
    flush_write(y*80 + (x >> 3), c);
}

/* Нарисовать закрашенный прямоугольник
 * (x1,y1,x2,y2,цвет), цвет=0..15
 *
 * Основано на одном из режимов (8-й режим) рисования VGA, когда
 * мы пишем в память цвет, но цвет пишется только в ту маску пикселей, 
 * которую мы задали 
 */
void fillrect(u16 x1, u16 y1, u16 x2, u16 y2, u8 c) {

    u16 i, j;
    
    // Выбор регистра Режим (5) и одновременная установка режима 2 (маски)
    IoWrite16(VGA_GC_INDEX, 0x0205); 
                                     
    // Нахождение маски для первой линия (слева)
    u16 m1 = (1 << (8 - (x1 & 7))) - 1;
    u16 m2 = ((0x7f80) >> (x2 & 7)) & 0xff;
    u16 xa = (x1 >> 3);
    u16 xb = (x2 >> 3);

    // (1) Рисование "длинного" по горизонтали прямоугольника
    if (xb > xa) {

        // А. Рисовать левую половину
        IoWrite16(VGA_GC_INDEX, 0x0008 | (m1 << 8)); 
        for (i = y1; i <= y2; i++) {
            flush_write(80*i + xa, c); 
        }

        // B. Сплошная линия (по 8 бит)
        IoWrite16(VGA_GC_INDEX, 0xFF08); 
        for (i = xa + 1; i < xb; i++) {
            for (j = y1; j <= y2; j++) {
                flush_write(80*j + i, c);
            }
        }
       
        // C. Рисовать правую половину
        IoWrite16(VGA_GC_INDEX, 0x0008 | (m2 << 8)); 
        for (i = y1; i <= y2; i++) {
            flush_write(80*i + xb, c);
        }

    // (2) В случае, если границы находятся на одном 8-битном столбце
    } else { 

        IoWrite16(VGA_GC_INDEX, 0x0008 | ((m1 & m2) << 8)); 
        for (i = y1; i <= y2; i++) {
            flush_write(80*i + xa, c);
        }
    }  
}

// Рисование линии на экране 
void line(u16 x1, u16 y1, u16 x2, u16 y2, u8 c) {

    int deltax = (x2 > x1) ? x2 - x1 : x1 - x2;
    int deltay = (y2 > y1) ? y2 - y1 : y1 - y2;
    int signx  = x1 < x2 ? 1 : -1;
    int signy  = y1 < y2 ? 1 : -1;

    int error = deltax - deltay;
    int error2;

    pixel(x2, y2, c);

    while (x1 != x2 || y1 != y2)
    {
        pixel(x1, y1, c);
        error2 = error * 2;

        if (error2 > -deltay) {
            error -= deltay;
            x1 += signx;
        }

        if (error2 < deltax) {
            error += deltax;
            y1 += signy;
        }
    }
}

// Рисовать прямоугольник
void rect(u16 x1, u16 y1, u16 x2, u16 y2, u8 c) {

    line(x1, y1, x2, y1, c);
    line(x2, y1, x2, y2, c);
    line(x2, y2, x1, y2, c);
    line(x1, y2, x1, y1, c);
}

// Рисование символа
void printc(u16 x, u16 y, unsigned char chr, u8 c) {

    int i, j;
    u8 font;

    for (i = 0; i < 16; i++) {

        font = bios_font[chr*16 + i];
        for (j = 0; j < 8; j++) {
            if (font & (1 << j)) {
                pixel(x + j, y + i, c);
            }            
        }
    }

}

// Вывести строку
void printzs(u16 x, u16 y, char* str, u8 c) {

    while (*str) {

        printc(x, y, *str, c);
        x += 8;
        str++;

    }
}
