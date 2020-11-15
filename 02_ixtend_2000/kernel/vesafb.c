#include "font_vga.h"
#include "font_tahoma.h"

#define COLOR_BLACK     0x0000
#define COLOR_WHITE     0xffff
#define COLOR_GRAY      0xc618
#define COLOR_DARKGRAY  0x8410

// Получение цвета по R,G,B=[0..255] 5(R) : 6(G) : 5(B)
uint16_t rgb16(uint8_t r, uint8_t g, uint8_t b) {
    
    return ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3);
}

// Рисование закрашенного прямоугольника
void fb_box(int16_t x1, int16_t y1, int16_t x2, int16_t y2, uint16_t color) {
    
    uint16_t i, j;

    for (i = y1; i <= y2; i++)
    for (j = x1; j <= x2; j++)
        fb_vesa[i*1024 + j] = color;
}

// Рисование линии на экране 
void fb_line(uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2, uint16_t color) {

    int deltax = (x2 > x1) ? x2 - x1 : x1 - x2;
    int deltay = (y2 > y1) ? y2 - y1 : y1 - y2;
    int signx  = x1 < x2 ? 1 : -1;
    int signy  = y1 < y2 ? 1 : -1;
    int error = deltax - deltay;
    int error2;

    fb_vesa[y2*1024 + x2] = color;

    while (x1 != x2 || y1 != y2) {

        fb_vesa[y1*1024 + x1] = color;        
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

// Пропечатать фиксированные шрифты
void print_fixedsys(uint16_t x, uint16_t y, char* string, uint16_t color) {
    
    uint8_t i, j;
    uint8_t chr;
    uint64_t fb;
    
    while (*string) {
        
        chr = *string;
        string++;
        
        // vga_bios_font
        for (i = 0; i < 16; i++) {
            
            fb = (y + i) * 1024 + x;
            for (j = 0; j < 8; j++) {
                
                if (vga_bios_font[chr*16 + i] & (1 << j)) {
                    fb_vesa[fb] = color;
                }
                
                fb++;                
            }            
        }
        
        x += 8;      
    }
}

// Ободок (без заливки)
void fb_rect(uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2, uint16_t color) {
    
    fb_line(x1, y1, x2, y1, color);
    fb_line(x1, y1, x1, y2, color);
    fb_line(x2, y2, x1, y2, color);
    fb_line(x2, y2, x2, y1, color);
    
}
