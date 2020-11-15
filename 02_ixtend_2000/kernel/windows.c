// Создание окон и работа с UI
void window(uint16_t x1, uint16_t y1, uint16_t w, uint16_t h) {
    
    uint16_t j;
    uint16_t x2 = x1 + w - 1;
    uint16_t y2 = y1 + h - 1;
    
    fb_box(x1, y1, x2, y2, rgb16(192,192,192));
    fb_rect(x1, y1, x2, y2, COLOR_BLACK);
        
    x1 += 2; y1 += 2;
    x2 -= 1; y2 -= 1;

    fb_line(x1, y1, x2, y1, COLOR_WHITE);
    fb_line(x2, y1, x2, y2, COLOR_DARKGRAY);
    fb_line(x1, y2, x2, y2, COLOR_DARKGRAY);
    fb_line(x1, y1, x1, y2, COLOR_WHITE);
    
    x1 += 2; y1 += 2;
    x2 -= 2;
    
    // Заголовок
    for (j = x1; j < x2; j++) {
        fb_line(j, y1, j, y1 + 19, rgb16(0, 128, 255 - (j - x1) * 128 / (x2 - x1)));
    }    
}

// Нарисовать панель
void textarea(uint16_t x1, uint16_t y1, uint16_t w, uint16_t h, uint16_t color) {
    
    uint16_t x2 = x1 + w - 1,
             y2 = y1 + h - 1;
       
    // Внешний ободок
    fb_line(x1, y1, x2, y1, COLOR_DARKGRAY);
    fb_line(x1, y1, x1, y2, COLOR_DARKGRAY);
    fb_line(x1, y2, x2, y2, COLOR_WHITE);
    fb_line(x2, y1, x2, y2, COLOR_WHITE);
    
    x1++; y1++;
    x2--; y2--;

    // Внутренний ободок
    fb_line(x1, y1, x2, y1, COLOR_BLACK);
    fb_line(x1, y1, x1, y2, COLOR_BLACK);
    fb_line(x1, y2, x2, y2, COLOR_GRAY);
    fb_line(x2, y1, x2, y2, COLOR_GRAY);
    
    x1++; y1++;
    x2--; y2--;
    
    // Область
    fb_box(x1, y1, x2, y2, color);    
}
