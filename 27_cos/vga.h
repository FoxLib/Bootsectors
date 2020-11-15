#include "stddef.h"

enum VGARegisters {
    
    VGA_DAC_READ_INDEX  = 0x3C7,
    VGA_DAC_WRITE_INDEX = 0x3C8,
    VGA_DAC_DATA        = 0x3C9,
    VGA_GC_INDEX        = 0x3CE,
    VGA_GC_DATA         = 0x3CF
};

static const unsigned char vgaPalette16[48] =
{
    0x00, 0x00, 0x00, //  0
    0x00, 0x00, 0x80, //  1
    0x00, 0x80, 0x00, //  2
    0x00, 0x80, 0x80, //  3
    0x80, 0x00, 0x00, //  4
    0x80, 0x00, 0x80, //  5
    0x80, 0x80, 0x00, //  6
    0xCC, 0xCC, 0xCC, //  7
    0x80, 0x80, 0x80, //  8
    0x00, 0x00, 0xFF, //  9
    0x00, 0xFF, 0x00, // 10
    0x00, 0xFF, 0xFF, // 11
    0xFF, 0x00, 0x00, // 12
    0xFF, 0x00, 0xFF, // 13
    0xFF, 0xFF, 0x00, // 14
    0xFF, 0xFF, 0xFF  // 15
};

struct VGADriver {

    int w;
    int h;
};

struct VGADriver vg;

/** % Prototypes % */

void init_vg();
void vg_pixel(int x, int y, uint c);
void vg_block(int x1, int y1, int x2, int y2, uint color);
void vg_line(int x1, int y1, int x2, int y2, uint color);
void vg_circle(int xc, int yc, int radius, uint color);
void vg_circle_fill(int xc, int yc, int radius, uint color);
int  vg_ttf_printc(int x, int y, uint8_t chr, uint8_t color);
int  vg_ttf_print(int x, int y, char* s, uint8_t color);
int  vg_ttf_printb(int x, int y, char* s, uint8_t color);

