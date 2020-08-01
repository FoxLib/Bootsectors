// https://pdos.csail.mit.edu/6.828/2008/readings/hardware/vgadoc/VESA.TXT

#include "stddef.h"
#include "dos866.h"

enum VGAColors {

    CL_BLACK = 0x0000,
    CL_CYAN  = 0x0410,
    CL_GRAY  = 0xC618,
    CL_WHITE = 0xFFFF,
};

struct VG_Current_State {

    int loc_x, loc_y;   // Позиция
    int fr, bg;         // Цвет
    int width, height;
};

struct VG_Current_State vg;

/** % Prototypes % */
uint16_t rgb(int r, int g, int b);
uint16_t C(uint32_t cl);

void vg_init();
void pset(int x, int y, uint16_t cl);
void block(int x1, int y1, int x2, int y2, uint16_t color);
void line(int x1, int y1, int x2, int y2, uint16_t color);
void lineb(int x1, int y1, int x2, int y2, uint16_t color);
void circle(int xc, int yc, int radius, uint16_t color);
void circle_fill(int xc, int yc, int radius, uint16_t color);
int  ttf_print_char(int x, int y, uint8_t chr, uint16_t color);
int  ttf_print(int x, int y, char* s, uint16_t color);
int  ttf_print_bold(int x, int y, char* s, uint16_t color);
void locate(int x, int y);
void color(int fr, int bg);
void print_char(char ch);
