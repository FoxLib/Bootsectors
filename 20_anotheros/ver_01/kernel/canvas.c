/**
 * @desc Слой над vga.c
 */

// Установка курсора
void at(int x, int y) {

    cursor.x = x;
    cursor.y = y;
}

// Цвета курсора
void color(int frcolor, int bgcolor) {

    cursor.frcolor = frcolor;
    cursor.bgcolor = bgcolor;
}

// Положение курсора и цвет
void colorat(int x, int y, int fr, int bg) {

    at(x, y);
    color(fr, bg);
}

// Получение точки из backbuffer
unsigned char get_point(int x, int y) {

    if (x < 0 || y < 0 || x >= vg.w || y >= vg.h)
        return 0;

    return vg.canvas[vg.w*y + x];
}

// Проверка на наличие МЫШИ в данной точке
unsigned char point(int x, int y) {

    int mx = cursor.mouse_x,
        my = cursor.mouse_y;

    // Не выходить за границы экрана
    if (x < 0 || y < 0 || x > 639 || y > 479)
        return 0;

    // Возможно, тут находится МЫШЬ
    if (mx <= x && x < mx + 12 && my <= y && y < my + 21) {

        int xn = x - mx;

        // Выбор точки и получение цвета
        switch (cursor.mouse_show ? (mouse_icon[y - my] >> (2*(11 - xn))) & 3 : 0) {

            case 1: return 7;
            case 2: return 15;
            case 3: return 8;
        }
    }

    return 0;
}

// ---------------------------------------------------------------------
// Нарисовать точку как на экране, так и в backbuffer
void pset(int x, int y, uint color) {

    if (x >= 0 && y >= 0 && x < vg.w && y < vg.h) {

        int mc = point(x, y);

        // Если тут есть мышь, то ее нарисовать вместо точки
        vg.pset(x, y, mc ? mc : color);

        // А саму точку отправить в BB
        vg.canvas[vg.w*y + x] = color;
    }
}

// Реально нарисовать блок
void block_draw(int x1, int y1, int x2, int y2, uint color) {

    uint i, j;

    // Неправильно заданы стороны
    if (x1 > x2 || y1 > y2)
        return;

    // Превышение верхних границ
    if (x1 >= vg.w || y1 >= vg.h)
        return;

    // Превышение нижних границ
    if (x2 < 0 || y2 < 0)
        return;

    // Корректировка границ
    if (x1 < 0) x1 = 0; if (x2 >= vg.w) x2 = vg.w - 1;
    if (y1 < 0) y1 = 0; if (y2 >= vg.h) y2 = vg.h - 1;

    // Запись данных в буфер
    for (i = y1; i <= y2; i++)
    for (j = x1; j <= x2; j++) {
        vg.canvas[vg.w*i + j] = color;
    }

    // На экране
    vg.block(x1, y1, x2, y2, color);
}

// Нарисовать блок :: очищается I=0, чтобы не вызвать прерывание мыши
void block(int x1, int y1, int x2, int y2, uint color) {

    int i, j;
    int mx  = cursor.mouse_x,
        my  = cursor.mouse_y,
        myh = my + 21;

    // Выходит за пределы рисования блока с мышью [0..+20]
    if (y1 <= y2 && ((y2 < my) || (y1 > my + 20))) {
        block_draw(x1, y1, x2, y2, color);

    }
    // Мышь показана, применить другой метод рисования блока
    else if (cursor.mouse_show) {

        // Случай, когда пересекает верхнюю границу (y1 < my < y2)
        if (y1 < my && my <= y2) {
            block_draw(x1, y1, x2, my - 1, color);
        }

        // Средний блок, один из краев принадлежит [my, my+20], либо оба находятся за границами
        if ( (my <= y1 && y1 < myh) || (my <= y2 && y2 < myh) || (y1 < my && y2 >= myh) ) {

            int h1 = y1 > my  ? y1 : my;
            int h2 = y2 < myh ? y2 : myh-1;

            // Рисовать саму мышь
            for (i = h1; i <= h2; i++)
            for (j = x1; j <= x2; j++)
                pset(j, i, color);
        }

        // Нижний блок [my+21..y2]
        if (y1 < myh && y2 >= myh) {
            block_draw(x1, myh, x2, y2, color);
        }
    }
    // Просто отобразить блок
    else {
        block_draw(x1, y1, x2, y2, color);
    }
}
// ---------------------------------------------------------------------

/** Печать символа на экране в режиме телетайпа
 * @param x, y позиция в пикселях
 * @param symb символ
 * @param color, bgcolor цвета
 */
void print_char(unsigned char chr) {

    int x = cursor.x;
    int y = cursor.y;

    int i, j, f = chr * 16;

    for (i = 0; i < 16; i++) {
        for (j = 0; j < 8; j++) {

            if (vga8x16Font[ f + i ] & (1 << (7 - j))) {
                pset(x + j, y + i, cursor.frcolor);

            } else if (cursor.bgcolor != -1) {
                pset(x + j, y + i, cursor.bgcolor);
            }
        }
    }

    cursor.x += 8;
}

// Распознать символ UTF8
unsigned char get_utf8(char** m) {

    unsigned char chr = **m;

    // Преобразовать UTF-8 в RUS
    if (chr == 0xD0) {

        (*m)++;
        chr = (**m) - 0x10;

    } else if (chr == 0xD1) {

        (*m)++;
        chr = (**m);
        chr = chr + (chr < 0xB0 ? 0x60 : 0x10);
    }

    return chr;
}

/** Пропечатать utf8 строку (прозрачную/непрозрачную)
 * @param bgcolor (-1 --  использовать прозрачноть)
 * @param maxchar
 */
int print(char* m) {

    int num = 0;
    unsigned char chr;

    while (*m) {

        chr = get_utf8(& m); m++; num++;
        print_char(chr);

        if (cursor.max_chars && num >= cursor.max_chars) {
            return 0;
        }
    }

    return num;
}

// Печать строки по по (X,Y)
int print_at(int x, int y, char* m) {

    cursor.x = x;
    cursor.y = y;

    return print(m);
}

// Печать hex-символа
void print_hex8(uint8_t hex) {

    char ht[3];

    ht[0] = (hex & 0xF0) >> 4;
    ht[1] = (hex & 0x0F);
    ht[2] = 0;

    ht[0] = ht[0] < 10 ? '0' + ht[0] : '7' + ht[0];
    ht[1] = ht[1] < 10 ? '0' + ht[1] : '7' + ht[1];

    print(ht);
}
void print_hex16(uint16_t hex) {

    print_hex8(hex >> 8);
    print_hex8(hex);
}
void print_hex32(uint32_t hex) {

    print_hex16(hex >> 16);
    print_hex16(hex);
}

// Печать числа
void print_int(int data) {

    char tmp[24];

    i2a(data, tmp);
    print(tmp);
}

/** Положение мыши
 * */
void mouse_xy(int x, int y) {

    cursor.mouse_x = x;
    cursor.mouse_y = y;
}

// Показать или скрыть мышь
void mouse_show(int show) {
    cursor.mouse_show = show;
}

// Обновить регион
void update_region(int x1, int y1, int x2, int y2) {

    int i, j, color;
    for (i = y1; i <= y2; i++)
    for (j = x1; j <= x2; j++) {

        color = point(j, i);
        vg.pset(j, i, color ? color : vg.canvas[vg.w*i + j]);
    }
}

// Обновить регион с мышью
void update_mouse() {

    update_region(cursor.mouse_x,    cursor.mouse_y,
                  cursor.mouse_x+12, cursor.mouse_y+21);
}

/*
 * Рисование линии по алгоритму Брезенхема
 * https://ru.wikipedia.org/wiki/Алгоритм_Брезенхэма
 */
void line(int x1, int y1, int x2, int y2, uint color) {

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
void circle(int xc, int yc, int radius, uint color) {

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
void circle_fill(int xc, int yc, int radius, uint color) {

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
