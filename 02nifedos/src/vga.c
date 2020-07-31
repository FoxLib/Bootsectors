#include "io.h"
#include "vga.h"
#include "tahoma.h"

// Подготовка и выделение памяти
void init_vg() {

    int i;

    vg.w = 640;
    vg.h = 480;

    // Режим 2 (регистр выбор режима 5) режим записи 1 слой цвета - 1 бит
    for (i = 0; i < 16; i++) {

        IoWrite8(VGA_DAC_WRITE_INDEX, i);
        IoWrite8(VGA_DAC_DATA, vgaPalette16[i*3 + 0] >> 2); // 0..63
        IoWrite8(VGA_DAC_DATA, vgaPalette16[i*3 + 1] >> 2); // 0..63
        IoWrite8(VGA_DAC_DATA, vgaPalette16[i*3 + 2] >> 2); // 0..63
    }

    IoWrite16(VGA_GC_INDEX, 0x0205);
}

// Нарисовать пиксель на экране
void vg_pixel(int x, int y, uint c) {

    char* vaddr = (char*)0xA0000;

    if (x >= 0 && x < vg.w && y >= 0 && y < vg.h) {

        uint16_t symbol = (x >> 3) + y*80;
        uint16_t mask   = 0x8000 >> (x & 7);

        IoWrite16(VGA_GC_INDEX, 0x08 | mask); // Установка маски, регистр 8 (вертикальная запись в слои)
        volatile uint8_t t = vaddr[ symbol ]; // Читать перед записью, иначе не сработает
        vaddr[ symbol ] = c;
    }
}

// Нарисовать блок
void vg_block(int x1, int y1, int x2, int y2, uint color) {

    int i, j, x;

    int x1i = x1 >> 3;
    int x2i = x2 >> 3;

    unsigned int xl = (  0xFF00 >> (x1 & 7)) & 0xFF00;
    unsigned int xr = (0x7F8000 >> (x2 & 7)) & 0xFF00;

    // Общая быстрая маска
    IoWrite16(VGA_GC_INDEX, 0xFF08);

    if (x1i + 1 < x2i) {

        for (i = y1; i <= y2; i++) {

            char* vm = (char*)(0xA0000 + 80*i);
            for (j = x1i + 1; j < x2i; j++) {
                volatile char t = vm[j]; vm[j] = color;
            }
        }
    }

    // Одновременная
    if (x1i == x2i) {

        IoWrite16(VGA_GC_INDEX, (xl & xr) | 0x08);
        for (i = y1; i <= y2; i++) {

            char* vm = (char*)(0xA0000 + 80*i);
            volatile char t = vm[x1i];
            vm[x1i] = color;
        }
    }

    // Левая и правая часть
    else {

        // Слева
        IoWrite16(VGA_GC_INDEX, xl | 0x08);
        for (i = y1; i <= y2; i++) {

            char* vm = (char*)(0xA0000 + 80*i);
            volatile char t = vm[x1i];
            vm[x1i] = color;
        }

        // Справа
        IoWrite16(VGA_GC_INDEX, xr | 0x08);
        for (i = y1; i <= y2; i++) {

            char* vm = (char*)(0xA0000 + 80*i);
            volatile char t = vm[x2i];
            vm[x2i] = color;
        }
    }
}

/*
 * Рисование линии по алгоритму Брезенхема
 * https://ru.wikipedia.org/wiki/Алгоритм_Брезенхэма
 */
void vg_line(int x1, int y1, int x2, int y2, uint color) {

    // Инициализация смещений
    int signx  = x1 < x2 ? 1 : -1;
    int signy  = y1 < y2 ? 1 : -1;
    int deltax = x2 > x1 ? x2 - x1 : x1 - x2;
    int deltay = y2 > y1 ? y2 - y1 : y1 - y2;
    int error  = deltax - deltay;
    int error2;

    // Если линия - это точка
    vg_pixel(x2, y2, color);

    // Перебирать до конца
    while ((x1 != x2) || (y1 != y2)) {

        vg_pixel(x1, y1, color);

        error2 = 2 * error;

        // Коррекция по X
        if (error2 > -deltay) {
            error -= deltay;
            x1 += signx;
        }

        // Коррекция по Y
        if (error2 < deltax) {
            error += deltax;
            y1 += signy;
        }
    }
}

/* Рисование окружности */
void vg_circle(int xc, int yc, int radius, uint color) {

    int x = 0,
        y = radius,
        d = 3 - 2*y;

    while (x <= y) {

        // Верхний и нижний сектор
        vg_pixel(xc - x, yc + y, color);
        vg_pixel(xc + x, yc + y, color);
        vg_pixel(xc - x, yc - y, color);
        vg_pixel(xc + x, yc - y, color);

        // Левый и правый сектор
        vg_pixel(xc - y, yc + x, color);
        vg_pixel(xc + y, yc + x, color);
        vg_pixel(xc - y, yc - x, color);
        vg_pixel(xc + y, yc - x, color);

        d += (4*x + 6);
        if (d >= 0) {
            d += 4*(1 - y);
            y--;
        }

        x++;
    }
}

// Рисование окружности
void vg_circle_fill(int xc, int yc, int radius, uint color) {

    int x = 0,
        y = radius,
        d = 3 - 2*y;

    while (x <= y) {

        // Верхний и нижний сектор
        vg_line(xc - x, yc + y, xc + x, yc + y, color);
        vg_line(xc - x, yc - y, xc + x, yc - y, color);

        // Левый и правый сектор
        vg_line(xc - y, yc + x, xc + y, yc + x, color);
        vg_line(xc - y, yc - x, xc + y, yc - x, color);

        d += (4*x + 6);
        if (d >= 0) {
            d += 4*(1 - y);
            y--;
        }

        x++;
    }
}

// Пропечатка шрифта, возвращается размер пропечатанной строки
int vg_ttf_printc(int x, int y, uint8_t chr, uint8_t color) {

    int i, j;

    int cp = 3 * chr;
    int font_x    = font_tahoma_positions[ cp ],
        font_y    = font_tahoma_positions[ cp+1 ],
        font_size = font_tahoma_positions[ cp+2 ];

    for (i = font_y; i < font_y + 12; i++) {
        
        int xp = x;
        for (j = font_x; j < font_x + font_size; j++) {

            if (font_tahoma[ i*15 + (j >> 3) ] & (1 << (7 - (j & 7))))
                vg_pixel(x, y, color);

            x++;
        }

        x = xp;
        y++;
    }

    return font_size;
}

// Печать строки (обычной, не BOLD)
// @return последняя позиция
int vg_ttf_print(int x, int y, char* s, uint8_t color) {

    int x_start = x;
    
    while (*s) {

        x += vg_ttf_printc(x, y, *s, color);
        s++;
    }

    return x;
}

// Печать строки BOLD
// @return последняя позиция
int vg_ttf_printb(int x, int y, char* s, uint8_t color) {

    int x_start = x;

    while (*s) {

        vg_ttf_printc(x, y, *s, color); x++;
        x += vg_ttf_printc(x, y, *s, color);
        s++;
    }

    return x;
}
