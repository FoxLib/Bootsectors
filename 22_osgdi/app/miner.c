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
                
            gdi_fillrect(miner, x,   y+1, x,    y+9, color);
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
    
    int color = 12;
    int clr[7] = {0, 0, 0, 0, 0, 0, 0};
    
    miner_semiseg(x, y,             0, color);
    miner_semiseg(x + 11, y,        1, color);
    miner_semiseg(x + 11, y + 10,   1, color);
    miner_semiseg(x, y,             2, color);
    miner_semiseg(x, y + 10,        2, color);
    miner_semiseg(x, y + 20,        3, color);
    miner_semiseg(x, y + 9,         4, color);
}

void miner_repaint() {

    int i, j;
    
    // Белые полосы
    gdi_fillrect(miner, 0, 0, 164, 3, 15);
    gdi_fillrect(miner, 0, 0, 3, 208, 15);
    
    // Внутренние окна
    gdi_ridge_rect(miner, 10, 10, 147, 35, 8, 15, 2);
    gdi_ridge_rect(miner, 10, 50, 147, 147, 8, 15, 2);
    
    // Окно очков и окно времени
    gdi_ridge_rect(miner, 16,    16, 40,        24,     8, 15, 1);
    gdi_ridge_rect(miner, 16+95, 16, 40,        24,     8, 15, 1);
    gdi_fillrect  (miner, 17,    17, 17+38,     23+16,  0);
    gdi_fillrect  (miner, 17+95, 17, 17+95+38,  23+16,  0);
    
    // Рисование области поля
    for (i = 0; i < 9; i++)
    for (j = 0; j < 9; j++) {
        gdi_ridge_rect(miner, 12 + j*16, 52 + i*16, 15, 15, 15, 8, 2);    
    }
    
    miner_digit(18,18,0);
}

// Игрулька
void make_miner() {

    miner = window_create(64, 64, 164, 208, "Сапер");

    // Регистрация событий
    window_event(miner, EVENT_REPAINT, & miner_repaint);
    
    // Активация нового окна и перерисовка
    window_activate(miner); 
    window_repaint(miner);
}
