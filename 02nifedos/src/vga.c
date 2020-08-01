#include "io.h"
#include "vga.h"
#include "tahoma.h"

uint16_t rgb(int r, int g, int b) {
    return ((r>>3)<<11) | ((g>>2)<<5) | (b>>3);
}

// Нарисовать пиксель на экране [R5:G6:B5]
void pset(int x, int y, uint16_t cl) {

    unsigned short* vm = (unsigned short*) 0xE0000000;
    if (x >= 0 && x < 1024 && y >= 0 && y < 768)
        vm[y*1024 + x] = cl;
}

// Нарисовать блок
void block(int x1, int y1, int x2, int y2, uint16_t cl) {

    if (x1 > 1024 || y1 > 768 || x2 < 0 || y2 < 0)
        return;

    if (x1 < 0) x1 = 0;
    if (y1 < 0) y1 = 0;
    if (x2 >= 1024) x2 = 1023;
    if (y2 >= 768) y2 = 767;

    for (int i = y1; i <= y2; i++)
    for (int j = x1; j <= x2; j++)
        pset(j, i, cl);
}

/*
 * Рисование линии по алгоритму Брезенхема
 * https://ru.wikipedia.org/wiki/Алгоритм_Брезенхэма
 */
void line(int x1, int y1, int x2, int y2, uint16_t color) {

    // Инициализация смещений
    int signx  = x1 < x2 ? 1 : -1;
    int signy  = y1 < y2 ? 1 : -1;
    int deltax = x2 > x1 ? x2 - x1 : x1 - x2;
    int deltay = y2 > y1 ? y2 - y1 : y1 - y2;
    int error  = deltax - deltay;
    int error2;

    // Если линия - это точка
    pset(x2, y2, color);

    // Перебирать до конца
    while ((x1 != x2) || (y1 != y2)) {

        pset(x1, y1, color);

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
void circle(int xc, int yc, int radius, uint16_t color) {

    int x = 0,
        y = radius,
        d = 3 - 2*y;

    while (x <= y) {

        // Верхний и нижний сектор
        pset(xc - x, yc + y, color);
        pset(xc + x, yc + y, color);
        pset(xc - x, yc - y, color);
        pset(xc + x, yc - y, color);

        // Левый и правый сектор
        pset(xc - y, yc + x, color);
        pset(xc + y, yc + x, color);
        pset(xc - y, yc - x, color);
        pset(xc + y, yc - x, color);

        d += (4*x + 6);
        if (d >= 0) {
            d += 4*(1 - y);
            y--;
        }

        x++;
    }
}

// Рисование окружности
void circle_fill(int xc, int yc, int radius, uint16_t color) {

    int x = 0,
        y = radius,
        d = 3 - 2*y;

    while (x <= y) {

        // Верхний и нижний сектор
        line(xc - x, yc + y, xc + x, yc + y, color);
        line(xc - x, yc - y, xc + x, yc - y, color);

        // Левый и правый сектор
        line(xc - y, yc + x, xc + y, yc + x, color);
        line(xc - y, yc - x, xc + y, yc - x, color);

        d += (4*x + 6);
        if (d >= 0) {
            d += 4*(1 - y);
            y--;
        }

        x++;
    }
}

// Пропечатка шрифта, возвращается размер пропечатанной строки
int ttf_printc(int x, int y, uint8_t chr, uint16_t color) {

    int i, j;

    int cp = 3 * chr;
    int font_x    = font_tahoma_positions[ cp ],
        font_y    = font_tahoma_positions[ cp+1 ],
        font_size = font_tahoma_positions[ cp+2 ];

    for (i = font_y; i < font_y + 12; i++) {

        int xp = x;
        for (j = font_x; j < font_x + font_size; j++) {

            if (font_tahoma[ i*15 + (j >> 3) ] & (1 << (7 - (j & 7))))
                pset(x, y, color);

            x++;
        }

        x = xp;
        y++;
    }

    return font_size;
}

// Печать строки (обычной, не BOLD)
// @return последняя позиция
int ttf_print(int x, int y, char* s, uint16_t color) {

    int x_start = x;

    while (*s) {

        x += ttf_printc(x, y, *s, color);
        s++;
    }

    return x;
}

// Печать строки BOLD
// @return последняя позиция
int ttf_printb(int x, int y, char* s, uint16_t color) {

    int x_start = x;

    while (*s) {

        ttf_printc(x, y, *s, color); x++;
        x += ttf_printc(x, y, *s, color);
        s++;
    }

    return x;
}
