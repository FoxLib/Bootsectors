
// Получение цвета по R,G,B=[0..255] 5(R) : 6(G) : 5(B)
uint16_t rgb16(uint8_t r, uint8_t g, uint8_t b);

// Рисование закрашенного прямоугольника
void fb_box(int16_t x1, int16_t y1, int16_t x2, int16_t y2, uint16_t color);

// Рисование линии на экране 
void fb_line(uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2, uint16_t color);

// Ободок (без заливки)
void fb_rect(uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2, uint16_t color);

// Пропечатать фиксированные шрифты
void print_fixedsys(uint16_t x, uint16_t y, char* string, uint16_t color);
