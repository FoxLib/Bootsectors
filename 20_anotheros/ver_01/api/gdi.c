/*
 * API вызовы на отрисовку
 */
 
void gdi_pset(int hwnd, int x, int y, uint32_t color) {
    
    struct window* win = & allwin[ hwnd ];

    // Коррекция границ
    if (x < 0) x = 0;
    if (x >= win->w - 4) x = win->w - 4;

    pset(win->x1 + 2 + x, win->y1 + 22 + y, color);    
}

void gdi_fillrect(int hwnd, int x1, int y1, int x2, int y2, uint32_t color) {

    struct window* win = & allwin[ hwnd ];

    // Коррекция границ
    if (x1 < 0) x1 = 0;
    if (y1 < 0) y1 = 0;
    if (x2 >= win->w - 4)  x2 = win->w - 4;
    if (y2 >= win->h - 24) y2 = win->h - 24;

    int _x1 = win->x1 + x1 + 2;
    int _x2 = win->x1 + x2 + 2;
    int _y1 = win->y1 + y1 + 22;
    int _y2 = win->y1 + y2 + 22;

    block(_x1, _y1, _x2, _y2, color);
}

// Рисуется блок с тенями thick = ширина
void gdi_ridge_rect(int hwnd, int x1, int y1, int w, int h, int color1, int color2, int thick) {

    int i;

    int x2 = x1 + w;
    int y2 = y1 + h;

    for (i = 0; i < thick; i++) {

        gdi_fillrect(hwnd, x1+i, y1+i, x2-i, y1+i, color1);
        gdi_fillrect(hwnd, x1+i, y1+i, x1+i, y2-i, color1);

        gdi_fillrect(hwnd, x2-i, y1+i, x2-i, y2-i, color2);
        gdi_fillrect(hwnd, x1+i, y2-i, x2-i, y2-i, color2);
    }
}

// Закрашенная окружность
void gdi_circle(int hwnd, int x, int y, int radius, uint color) {
    
    struct window* win = & allwin[ hwnd ];
    
    x = win->x1 + x + 2; 
    y = win->y1 + y + 22;
    
    circle(x, y, radius, color);
}

// Закрашенная окружность
void gdi_circle_fill(int hwnd, int x, int y, int radius, uint color) {
    
    struct window* win = & allwin[ hwnd ];
    
    x = win->x1 + x + 2; 
    y = win->y1 + y + 22;
    
    circle_fill(x, y, radius, color);
}
