#include "vga.h"
#include "gui.h"

// Отрисовать окно
void gui_draw_window(char* name, int x, int y, int w, int h) {

    int x2 = x + w, y2 = y + h;
    block(x, y, x2, y2, C(0xd5d5d5));
    lineb(x, y, x2, y2, 0);
    block(x+2, y+2, x2-2, y+24, C(0x77b584));

    // Нарисовать шрифт с тенью
    ttf_print(x + 7, y + 9, name, CL_BLACK);
    ttf_print(x + 6, y + 8, name, CL_WHITE);
}
