#include "io.h"
#include "vga.h"
#include "stdlib.h"

// Инициализировать значениями
void vg_init() {

    vg.width     = 640;
    vg.height    = 480;
    vg.font_id   = FONT_TREBUCHETMS_14;
    vg.font_bold = 0;
    vg.db        = (word*) malloc(2 * vg.width * vg.height);
    vg.mx        = vg.width >> 1;
    vg.my        = vg.height >> 1;

    locate(0, 0);
    color(CL_WHITE, -1);
}

// 5:6:5
uint16_t rgb(int r, int g, int b) { return ((r>>3)<<11) | ((g>>2)<<5) | (b>>3); }

// Конвертация 24 -> 16
uint16_t C(uint32_t cl) {
    return
        (((cl & 0xFF0000) >> 19) << 11) |
        (((cl & 0xFF00) >> 10) << 5) |
        (( cl & 0xFF) >> 3);
}

// Нарисовать пиксель на экране [R5:G6:B5]
void pset(int x, int y, uint16_t cl) {

    unsigned short* vm = (unsigned short*) 0xE0000000;

    if (x >= 0 && x < vg.width && y >= 0 && y < vg.height) {

        uint32_t idx = x + y*vg.width;

        vg.db[idx] = cl;

        // Отобразить мышь, если нужно
        if (vg.mx <= x && vg.my <= y && x < vg.mx + 11 && y < vg.my + 19) {

            byte mpoint = mouse_cursor[y - vg.my][x - vg.mx];

            if (mpoint == 1) cl = CL_BLACK;
            if (mpoint == 2) cl = CL_WHITE;
        }

        vm[idx] = cl;
    }
}

// Получение цвета точки
uint16_t point(int x, int y) {

    if (x >= 0 && x < vg.width && y >= 0 && y < vg.height) {
        return vg.db[x + y*vg.width];
    }

    return 0;
}

// Нарисовать блок
void block(int x1, int y1, int x2, int y2, uint16_t cl) {

    if (x1 >= vg.width || y1 >= vg.height || x2 < 0 || y2 < 0)
        return;

    if (x1 < 0) x1 = 0;
    if (y1 < 0) y1 = 0;
    if (x2 >= vg.width)  x2 = vg.width-1;
    if (y2 >= vg.height) y2 = vg.height-1;

    for (int i = y1; i <= y2; i++)
    for (int j = x1; j <= x2; j++)
        pset(j, i, cl);
}

void cls(uint16_t cl) {
    block(0, 0, vg.width, vg.height, cl);
}

/** Рисование линии по алгоритму Брезенхема
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

// Рисование контура
void lineb(int x1, int y1, int x2, int y2, uint16_t color) {

    block(x1, y1, x2, y1, color);
    block(x1, y1, x1, y2, color);
    block(x2, y1, x2, y2, color);
    block(x1, y2, x2, y2, color);
}

/** Рисование окружности */
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

// Печать символа TTF
int font_draw_symbol(char s) {

    unsigned char ch = (unsigned char) s;
    int x = vg.loc_x,
        y = vg.loc_y,
        w = 0;

    if (vg.font_id == FONT_TREBUCHETMS_14) {

        ch -= 32;

        // Позиция и ширина буквы
        int st = map_trebuchetms14[ch][0] + 256*map_trebuchetms14[ch][1];
            w  = map_trebuchetms14[ch][2];

        for (int i = 0; i < 14; i++) {

            for (int j = 0; j < w; j++) {

                int ct = st + j;
                int bm = font_trebuchetms14[ct>>3][i] & (1 << (ct&7));

                if (bm) {

                    pset(x + j, y + i, vg.fr);
                    if (vg.font_bold) pset(x + j + 1, y + i, vg.fr);
                }
                else if (vg.bg >= 0) {

                    pset(x + j, y + i, vg.bg);
                    if (vg.font_bold) pset(x + j + 1, y + i, vg.bg);
                }
            }
        }

        vg.loc_x += (1 + w + vg.font_bold);
    }

    return w;
}

// Пропечатка символов
int font_print(char* s) {

    int n = 0;
    while (s[n]) {

        font_draw_symbol(s[n]);
        n++;
    }

    return n;
}

// Позиционирование по пикселям
void locate(int x, int y) {

    vg.loc_x = x;
    vg.loc_y = y;
}

// Цвета
void color(int fr, int bg) { vg.fr = fr; vg.bg = bg; }
void colorfr(int fr) { vg.fr = fr; }
void colorbg(int bg) { vg.bg = bg; }

// Начертание
void bold(int v) { vg.font_bold = v ? 1 : 0; }

// Пропечать символа
void print_char(char ch) {

    for (int i = 0; i < 16; i++) {

        int mask = dos866[ch][i];
        for (int j = 0; j < 8; j++) {

            if (mask & (1 << (7 - j)))
                pset(vg.loc_x + j, vg.loc_y + i, vg.fr);
            else if (vg.bg >= 0)
                pset(vg.loc_x + j, vg.loc_y + i, vg.bg);
        }
    }

    vg.loc_x += 8;
}
