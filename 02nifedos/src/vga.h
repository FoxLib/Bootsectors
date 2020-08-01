#include "stddef.h"

enum VGAColors {

    CL_BLACK = 0x0000,
    CL_CYAN  = 0x0410,
    CL_WHITE = 0xFFFF,
};

/** % Prototypes % */
uint16_t rgb(int r, int g, int b);
uint16_t C(uint32_t cl);

void pset(int x, int y, uint16_t cl);
void block(int x1, int y1, int x2, int y2, uint16_t color);
void line(int x1, int y1, int x2, int y2, uint16_t color);
void circle(int xc, int yc, int radius, uint16_t color);
void circle_fill(int xc, int yc, int radius, uint16_t color);
int  ttf_printc(int x, int y, uint8_t chr, uint16_t color);
int  ttf_print(int x, int y, char* s, uint16_t color);
int  ttf_printb(int x, int y, char* s, uint16_t color);
