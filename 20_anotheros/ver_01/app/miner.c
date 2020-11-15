int miner;

// Рисовать один из семисегментов
void miner_semiseg(int x, int y, int id, int color) {

    switch (id) {

        case 0: // Верхняя линия

            gdi_fillrect(miner, x+1, y,   x+10, y,   color);
            gdi_fillrect(miner, x+2, y+1, x+9,  y+1, color);
            gdi_fillrect(miner, x+3, y+2, x+8,  y+2, color);
            break;

        case 1: // Правая линия

            gdi_fillrect(miner, x,   y+1, x,    y+9,  color);
            gdi_fillrect(miner, x-1, y+2, x-1,  y+8,  color);
            gdi_fillrect(miner, x-2, y+3, x-2,  y+7,  color);
            break;

        case 2: // Левая линия

            gdi_fillrect(miner, x,   y+1, x,    y+9, color);
            gdi_fillrect(miner, x+1, y+2, x+1,  y+8,  color);
            gdi_fillrect(miner, x+2, y+3, x+2,  y+7,  color);
            break;

        case 3: // Нижняя линия

            gdi_fillrect(miner, x+1, y,   x+10, y,   color);
            gdi_fillrect(miner, x+2, y-1, x+9,  y-1, color);
            gdi_fillrect(miner, x+3, y-2, x+8,  y-2, color);
            break;

        case 4: // Средняя

            gdi_fillrect(miner, x+2, y,   x+9,   y,   color);
            gdi_fillrect(miner, x+1, y+1, x+10,  y+1, color);
            gdi_fillrect(miner, x+2, y+2, x+9,   y+2, color);
            break;
    }
}

// Рисование одной цифры
void miner_digit(int x, int y, int digit) {

    int color_bg = 4;
    int color_fr = 12;
    int i, j;
    int mask = 0x20;

    // 7 сегментов
    miner_semiseg(x,      y,        0, color_bg);
    miner_semiseg(x + 11, y,        1, color_bg);
    miner_semiseg(x + 11, y + 10,   1, color_bg);
    miner_semiseg(x,      y,        2, color_bg);
    miner_semiseg(x,      y + 10,   2, color_bg);
    miner_semiseg(x,      y + 20,   3, color_bg);
    miner_semiseg(x,      y + 9,    4, color_bg);

    // Затемнение
    for (i = 0; i <= 20; i++)
    for (j = i % 2; j <= 11; j+=2)
        gdi_pset(miner, x + j, y + i, 0);

    switch (digit) {

        case 0: mask = 0b0111111; break;
        case 1: mask = 0b0000110; break;
        case 2: mask = 0b1011011; break;
        case 3: mask = 0b1001111; break;
        case 4: mask = 0b0000000; break;
        case 5: mask = 0b1101101; break;
        case 6: mask = 0b1111101; break;
        case 7: mask = 0b0000111; break;
        case 8: mask = 0b1111111; break;
        case 9: mask = 0b1101111; break;
    }

    // Рисование засвеченных семисегментов
    if (mask & 0x01) miner_semiseg(x,      y,        0, color_fr);
    if (mask & 0x02) miner_semiseg(x + 11, y,        1, color_fr);
    if (mask & 0x04) miner_semiseg(x + 11, y + 10,   1, color_fr);
    if (mask & 0x08) miner_semiseg(x,      y + 20,   3, color_fr);
    if (mask & 0x10) miner_semiseg(x,      y + 10,   2, color_fr);
    if (mask & 0x20) miner_semiseg(x,      y,        2, color_fr);
    if (mask & 0x40) miner_semiseg(x,      y + 9,    4, color_fr);
}

// Перерисовать целое окно
void miner_repaint() {

    int i, j;

    // Белые полосы
    gdi_fillrect(miner, 0, 0, 164, 3, 15);
    gdi_fillrect(miner, 0, 0, 3, 208, 15);

    // Внутренние окна
    gdi_ridge_rect(miner, 10, 10, 147, 35, 8, 15, 2);
    gdi_ridge_rect(miner, 10, 50, 147, 147, 8, 15, 2);

    // Окно очков и окно времени
    gdi_ridge_rect(miner, 16,    16, 44,        24,     8, 15, 1);
    gdi_ridge_rect(miner, 16+90, 16, 44,        24,     8, 15, 1);
    gdi_fillrect  (miner, 17,    17, 17+42,     23+16,  0);
    gdi_fillrect  (miner, 17+90, 17, 17+90+42,  23+16,  0);

    // Рисование области поля
    for (i = 0; i < 9; i++)
    for (j = 0; j < 9; j++) {
        gdi_ridge_rect(miner, 12 + j*16, 52 + i*16, 15, 15, 15, 8, 2);
    }

    // Вывести цифры
    miner_digit(18,  18, 0); miner_digit(18+14,  18, 0); miner_digit(18+28,  18, 0);
    miner_digit(108, 18, 0); miner_digit(108+14, 18, 0); miner_digit(108+28, 18, 0);

    // Кнопка с лицом
    gdi_ridge_rect(miner, 70, 16, 24, 24, 15, 8, 2);
    
    // Лицо
    gdi_circle_fill(miner, 82, 28, 8, 14);
    gdi_circle     (miner, 82, 28, 8, 0);
    
    gdi_fillrect(miner, 79, 25, 80, 26, 0);
    gdi_fillrect(miner, 84, 25, 85, 26, 0);
    gdi_fillrect(miner, 80, 31, 84, 31, 0);
}

void miner_mouseclick() {

    gdi_pset(miner, 8, 8, 0);

}

// Игрулька
void make_miner() {

    miner = window_create(64, 64, 164, 208, "Сапер");

    // Регистрация событий
    window_event(miner, EVENT_REPAINT,   & miner_repaint);
    window_event(miner, EVENT_MOUSEDOWN, & miner_mouseclick);

    // Активация нового окна и перерисовка
    window_repaint(miner);
}
