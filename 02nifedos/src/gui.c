#include "vga.h"
#include "gui.h"
#include "stdio.h"

void gui_init() {
}

// Отрисовать окно
void gui_draw_window(char* name, int x, int y, int w, int h) {

    int x2 = x + w, y2 = y + h;
    block(x, y, x2, y2, C(0xd5d5d5));
    lineb(x, y, x2, y2, 0);
    block(x+2, y+2, x2-2, y+19, C(0x0084b5));

    bold(1);
    font(FONT_TREBUCHETMS_14);
    locate(x + 7, y + 5); colorfr(CL_BLACK); print(name);
    locate(x + 6, y + 4); colorfr(CL_WHITE); print(name);
}
